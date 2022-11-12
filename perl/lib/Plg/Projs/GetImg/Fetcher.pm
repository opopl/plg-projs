
package Plg::Projs::GetImg::Fetcher;

use strict;
use warnings;

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use File::Path qw( mkpath rmtree );
use File::Basename qw(basename dirname);

use Data::Dumper qw(Dumper);
use File::Which qw(which);  

use URI::Split qw(uri_split);
use String::Util qw(trim);

use File::Copy qw( move );

use Clone qw(clone);

use File::stat;

use Image::Info qw(
    image_info
    image_type
);

use base qw(
    Base::Obj
);

use Base::Util qw(
  md5sum
);

use Base::Arg qw(
  hash_inject
);

use String::Util qw(trim);

use Base::String qw(
  str_split
  str_split_trim
);

use Base::DB qw( 
    dbh_select_as_list
    dbh_select_fetchone
    dbh_insert_hash

    dbh_base2info
);

use Plg::Projs::Tex qw(
    texify 
);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub d_rm_file {
  my ($self) = @_;

  my $d = $self->{d};
  return $self unless $d && $d->{img_file} && -f $d->{img_file};

  rmtree $d->{img_file};
  $d->{'@'}->{fs} = 0;
  return $self;
}

sub d_block_import {
    my ($self) = @_;

    my ($d, $block) = @{$self}{qw(d block)};
    return $self unless ( $d && $block && $block eq 'import');

    my ($imgman) = $self->{imgman};
    return $self unless $imgman;

    my ($path, $match, $insert, $tags) = @{$d}{qw( path match insert tags )};
    my $exts = [];

    my $tags_a = [];
    push @$tags_a, 
        $tags ? str_split_trim($tags => ",") : (); 

    my ($proj, $sec, $rootid) = @{$self}{qw( proj sec rootid )};

    if (-d $path) {
        my @imgs = $imgman->_fs_find_imgs({
            find  => { max_depth => 1 },
            dirs  => [ $path ],
            exts  => $exts,
            match  => $match ? [ split (',' => $match) ] : [],
            #limit => 5,
        });
        $DB::single = 1;
        #we import into database all screenshots on the filesystem
        foreach my $img_path (@imgs) {
            $imgman->pic_add({
                file => $img_path,
                tags => $tags_a,
    
                proj   => $proj,
                sec    => $sec,
                rootid => $rootid,
    
                mv => 0,
            });
        }
        1;
    }

    $self->{d} = undef;

    return $self;
}

sub d_process {
    my ($self) = @_;

    my $d = $self->{d};
    return $self unless $d && $d->{url};

    $d->{'@'} ||= {};

    $self
        ->d_get_inum
        ->d_get_file
        ;

    $DB::single = 1;
    my $fetch_ok = $self->_fetch;

    $self->db_insert_img if $fetch_ok;

    $self->{d} = undef;

    return $self;
}

# process previosly collected block
sub process_block {
    my ($self) = @_;

    return $self unless $self->{block};

    $self->{$_} = undef for qw(is_local is_global);

    $DB::single = 1;
    $self
       ->d_process
       ->d_block_import; 

    $self->{block} = undef;

    return $self;
}

sub init {
    my ($self) = @_;
    
    #$self->SUPER::init();
    #
    my $h = {
       # structure with image information
       d    => undef,

       # local running vars within ifcmt ... fi block
       locals => undef,

       # global variables for any ifcmt block
       globals => {},

       # name of block
       block => undef,

       img_root => $ENV{IMG_ROOT},

       keys => [qw(url caption tags name)],

       file  => undef,
       flines => [],
       flines_new => [],

       img      => undef,
       img_path => undef,

       is_cmt => undef,
       lnum => 0,

       root => undef,
       proj => undef,
       sec  => undef,
    };
 
    hash_inject($self, $h);
    return $self;
}

sub db_insert_img {
  my ($self) = @_;

  my $d = $self->{d};
  return $self unless $d;

  my $iif = image_info($d->{img_file}) || {};
  $d->{$_} = $iif->{$_} for(qw( width height));

  my $ins = {};

  my @keys_self = qw( proj rootid sec );
  my @keys_d = qw( inum url img size );
  my @keys_d_str = qw( caption tags name type md5 width height );

  $ins->{$_} = $self->{$_} for(@keys_self);

  $ins->{$_} = $d->{$_} for(@keys_d);
  $ins->{$_} = $d->{$_} // '' for(@keys_d_str);
  $DB::single = 1;

  my $ok = 1;
  while (1) {

    $ok &&= eval {
      dbh_insert_hash({
         t => 'imgs',
         i => q{ INSERT OR REPLACE },
         h => $ins
      });
    };
    $@ && do { warn $@; $ok = 0; };

    $ok &&= eval {
      dbh_base2info({
         'tbase'  => 'imgs',
         'bwhere' => { url => $d->{url} },
         'jcol'   => 'url',
         'b2i'    => { 'tags' => 'tag' },
         'bcols'  => [qw( tags )],
      });
    };
    $@ && do { $ok = 0; warn $@; };

    rmtree $d->{img_file} unless $ok;

    last;
  }

  $self->d_push_status('ok') if $ok;

  return $self;
}

sub _reload {
  my ($self) = @_;

  my $reload = $self->{reload}
        || $self->_val_('d reload')
        || $self->_val_('locals reload')
        || $self->_val_('globals reload')
        ;

  return $reload;
}

sub _fetch_on {
  my ($self) = @_;

  my $d = $self->{d};
  return unless $d && $d->{img_file};

  ((! -f $d->{img_file}) || $d->{img_err}) ? 1 : 0;

}

sub f_read {
  my ($self, $ref) = @_;

  $ref ||= {};

  my $file = $ref->{file} || $self->{file};

  push @{$self->{flines}}, read_file $file;

  return $self;
}

sub _inum_max {
  my ($self) = @_;

  my $ref = { q => 'SELECT MAX(inum) FROM imgs' };
  my $max  = dbh_select_fetchone($ref) // 0;

  return $max;
}

sub d_get_inum {
  my ($self) = @_;

  my $d = $self->{d};
  return $self unless $d && $d->{url};

  @{$d}{qw(inum img ext)} = dbh_select_as_list({
      q => q{ SELECT inum, img, extension(img) AS ext FROM imgs WHERE url = ? },
      p => [ $d->{url} ],
  });
  $d->{'@'}->{db} = $d->{inum} ? 1 : 0;

  unless($d->{inum}){
      my $max = $self->_inum_max;
      $d->{inum} = ($max) ? ($max + 1) : 1;
      $d->{ext} = 'jpg';
      $d->{img} = join("." => @{$d}{qw( inum ext )});
  }

  return $self;
}

sub d_get_file {
  my ($self) = @_;

  my $d = $self->{d};
  return $self unless $d;

  $self->d_get_inum unless $d->{inum};

  unless($d->{img}){
     $d->{ext} ||= 'jpg';
     $DB::single = 1 unless $d->{inum};
     $d->{img} = sprintf(q{%s.%s},@{$d}{qw( inum ext )} );
  }

  $d->{img_file} = catfile($self->{img_root},$d->{img});

  $d->{'@'}->{fs} = -f $d->{img_file} ? 1 : 0;

  return $self;
}

sub loop {
  my ($self) = @_;

  my @flines = @{$self->{flines} || []};
  $self->{flines_new} ||= [];

  while(@flines){
    local $_ = shift @flines;

    $self->{lnum}++; chomp;
    $self->{line} = $_;

    push @{$self->{flines_new}}, $_;

    next if /^\s*%/;

###m_ifcmt
    m/^\\ifcmt\s*$/g && do { 
        $self->{is_cmt} = 1; 
        $self->{locals} = {}; 
        next; 
    };

    m/^\\fi\s*$/g && do { 
       $self->process_block;
       $self->{is_cmt} = undef; 
       $self->{locals} = undef; 
       next; 
    };

    next unless $self->{is_cmt};

    m/^\s*(locals|globals)\s*$/g && do {
       $self->process_block;

       my $k = trim($1);

       # is_local => 1
       # or is_global => 1
       $self->{'is_' . $k} = 1; 
       $self->{block} = $k;
    };

###m_import
    m/^\s*(import)\s*$/g && do {
       $self->process_block;

       $self->{d} = {};
       $self->{block} = $1;
    };

###m_pair
    # (prefix @, optional)key value
    m/^\s*(@|)(\w+)\s+(\S+.*)$/g && do {
       my ($d, $locals, $globals) = @{$self}{qw(d locals globals)};

       # prefix: if =@ then it is a key-value pair for some block
       my $pref = $1;

       my $k = trim($2);
       my $v = trim($3);

       if (!$pref && grep { /^$k$/ } qw( pic doc ig igc ) ){
          # process previously stored block
          $self->process_block;

          $self->{block} = $k;
          $self->{d} = { url => $v, type => $k };
          next;
       }

       $d->{$k} = $v if $d;

       $locals->{$k}  = $v if $self->{is_local};
       $globals->{$k} = $v if $self->{is_global};
    };

  }

  return $self;
}

sub _subs_url {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($url, $img_file, $sec) = @{$ref}{qw( url img_file sec )};
    my $lwp  = $self->{lwp};

    my @subs = (
        sub { 
            my $curl = which 'curl';
            return unless $curl;

            my $hdr;
            #my $hdr = 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:96.0) Gecko/20100101 Firefox/96.0';
            $hdr = 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux i686 on x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2820.59 Safari/537.36';
            $hdr = 'User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2226.0 Safari/537.36';
            my $o_hdr = $hdr ? sprintf('-H "%s"',$hdr) : '';
    
            print qq{try: curl} . "\n";
    
            my $url_s = $^O eq 'MSWin32' ? qq{"$url"} : qq{"$url"};
    
            my $cmd = qq{ $curl $o_hdr -o "$img_file" $url_s };
            print qq{command:\n\t$cmd} . "\n";
            my $x = qx{ $cmd 2>&1 };
            #$self->debug(["Command:", $x]);
            return 'curl';
        },
        sub { 
            print qq{try: lwp} . "\n";
    
            my $res = $lwp->mirror($url,$img_file);
            unless ($res->is_success) {
                my $r = {
                    msg         => 'LWP Error',
                    url         => $url,
                    status_line => $res->status_line,
                };
                warn Dumper($r) . "\n";
            }
            return 'lwp';
        },
        sub {
            my $r = {
                url    => $url,
                proj   => $self->{proj},
                rootid => $self->{rootid},
                sec    => $sec,
            };
            warn sprintf('URL Download Failure: %s',Dumper($r)) . "\n";
        }
  );

  return @subs;

}

sub d_push_status {
  my ($self, $key) = @_;

  my $d  = $self->{d};
  my $imgman = $self->{imgman};

  return $self unless $d && $imgman;
  
  push @{$imgman->{$key}}, clone($d);

  return $self;
}

sub _fetch {
  my ($self) = @_;

  my $d = $self->{d};
  return unless $d && $d->{img_file};

  return if !$self->_reload 
        && $d->{'@'}->{fs} 
        && $d->{'@'}->{db};

  $self->d_rm_file;

  my $imgman  = $self->{imgman};

  my $sec = $self->{sec};

  my @subs = $self->_subs_url({ 
     url      => $d->{url},
     img_file => $d->{img_file},
     sec      => $sec,
  });

  my ($m, @m); push @m,
     'x' x 50,
     'Try downloading picture:',
     '  proj:     ' . $self->{proj},
     '  sec:      ' . $sec,
     '  url:      ' . $d->{url},
     '  img:      ' . $d->{img},
     '  caption:  ' . ($d->{caption} || ''),
     ;

  $m = join("\n",@m);
  print $m . "\n";

  while($self->_fetch_on){
     my $s  = shift @subs;
     my $ss = $s->();
  }

  my $dd = {
     url  => $d->{url},
     img  => $d->{img},
     sec  => $sec,
  };

  unless(-f $d->{img_file}){
     print qq{DOWNLOAD FAIL: } . $d->{img} . "\n";
     $self->d_push_status('fail');
     return ;
  }else{
     print qq{DOWNLOAD SUCCESS: } . $d->{img} . "\n";
  }

  my $itp = image_type($d->{img_file}) || {};
  my $iif = image_info($d->{img_file}) || {};

  my $media_type_str = $iif->{file_media_type} || '';
  my ($img_type) = ( $media_type_str =~ m{image\/(\w+)} );
        
  $d->{img_err} = $iif->{error};
  if ($d->{img_err}) {
     print qq{image_info FAIL: } . $d->{img} . "\n";
     print '  ' .  $d->{img_err} . "\n";
     return;
  }else{
     print qq{image_info OK: } . $d->{img} . "\n";
     foreach my $k (qw(file_media_type)) {
        print qq{   $k => } . $iif->{$k} . "\n" if $iif->{$k};
     }
  }

  my $ft  = lc( $itp->{file_type} || '');
  print qq{image file_type: $ft} . "\n";

  $ft = 'jpg' if $ft eq 'jpeg';

  if ($ft) {
     if ($ft ne $d->{ext}) {
        $d->{ext} = $ft;
        my $img_new      = sprintf(q{%s.%s},@{$d}{qw(inum ext)});
        $d->{img} = $img_new;
    
        my $img_file_new = catfile($self->{img_root},$img_new);
        move($d->{img_file}, $img_file_new);
        $d->{img_file} = $img_file_new;
     }

     if (grep { /^$d->{ext}$/ } qw(gif webp bmp)) {
        my $img_jpg = sprintf(q{%s.%s},$d->{inum},'jpg');
        my $img_file_jpg = catfile($self->{img_root},$img_jpg);

        my $cmd = sprintf(q{convert %s %s},$d->{img_file}, $img_file_jpg);

        printf(q{Convert: %s => %s} . "\n", basename($d->{img_file}), $img_jpg);

        system("$cmd");

        unless(-f $img_file_jpg) {
            print 'Convert FAIL' . "\n";
            return ;
        }
        print 'Convert OK' . "\n";
        rmtree $d->{img_file};
        $d->{img_file} = $img_file_jpg;
        $d->{img} = $img_jpg;
        $d->{ext} = 'jpg';
     }
  }

  my $fs = -f $d->{img_file} ? 1 : 0;

  return unless $fs;
  $d->{size} = stat($d->{img_file})->size;
  return unless $d->{size};

  $d->{'@'}->{fs} = 1;

  $d->{md5} = md5sum($d->{img_file});

  print '=' x 50 . "\n";
  print qq{ Final image location: } . basename($d->{img_file}) . "\n";
  print qq{   Size: } . $d->{size} . "\n";
  print qq{   MD5:  } . $d->{md5} . "\n";
  print '=' x 50 . "\n";

  return 1;
}
# endof: _fetch
# see also: db_insert_img


1;
 

