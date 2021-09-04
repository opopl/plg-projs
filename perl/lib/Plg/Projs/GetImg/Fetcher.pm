
package Plg::Projs::GetImg::Fetcher;

use strict;
use warnings;

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use File::Path qw( mkpath rmtree );
use File::Basename qw(basename dirname);

use Data::Dumper qw(Dumper);
use File::Which qw(which);  


use Image::Info qw(
    image_info
    image_type
);

use base qw(
    Base::Obj
);

use Base::Arg qw(
  hash_inject
  hash_update
);

use String::Util qw(trim);

use Base::String qw(
  str_split
);

use Base::DB qw( 
    dbi_connect 
    dbh_do
    dbh_select
    dbh_select_fetchone
    dbh_insert_hash
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

sub d_process {
    my ($self) = @_;

    my $d = $self->{d};
    return $self unless $d;

    my $url = $d->{url};

    my $db = {};
    @{$db}{qw(inum img)} = dbh_select_as_list({
        q => q{ SELECT inum, img FROM imgs WHERE url = ? },
        p => [ $url ],
    });

    $self->db_get_inum_max unless $db->{inum};

    $self->d_img_file;

    my $fetch_ok = $self->_fetch;

    $self->db_insert_img if $fetch_ok;

    $self->{d} = undef;

    return $self;
}

sub process_block {
    my ($self) = @_;

    return $self unless $self->{block};

    $self->{$_} = undef for qw(is_local is_global);

    $self->d_process;

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
       locals => {},

       # global variables for any ifcmt block
       globals => {},

       # name of block
       block => undef,

       img_root => $ENV{IMG_ROOT},

       keys => [qw(url caption tags name)],

       file  => undef,
       flines => [],

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

  my $ok = dbh_insert_hash({
       t => 'imgs',
       i => q{ INSERT OR REPLACE },
       h => {
           proj    => $self->{proj},
           rootid  => $self->{rootid},
           sec     => $self->{sec},

           inum    => $d->{inum},
           url     => $d->{url},
           img     => $d->{img},
           ext     => $d->{ext},
           caption => $d->{caption} || '',
           tags    => $d->{tags} || '',
           name    => $d->{name} || '',
           type    => $d->{type} || '',
       },
  });

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
  return unless $d;

  ((! -e $d->{img_file}) || $d->{img_err}) ? 1 : 0;

}

sub f_read {
  my ($self, $ref) = @_;

  $ref ||= {};

  my $file = $ref->{file} || $self->{file};

  push @{$self->{flines}}, read_file $file;

  return $self;
}

sub db_get_inum_max  {
  my ($self) = @_;

  my $d = $self->{d};
  return $self unless $d;

  my $ref = {
     q => q{ SELECT MAX(inum) FROM imgs },
  };
  my $max  = dbh_select_fetchone($ref);
  $d->{inum} = ($max) ? ($max + 1) : 1;

  return $self;
}

sub d_img_file {
  my ($self) = @_;

  my $d = $self->{d};
  return $self unless $d;

  my $ext;

  unless($d->{img}){
      my ($scheme, $auth, $path, $query, $frag) = uri_split($d->{url});
      my $bname = basename($path);
      ($ext) = ($bname =~ m/\.(\w+)$/);
      $ext ||= 'jpg';
      $ext = lc $ext;
      $ext = 'jpg' if $ext eq 'jpeg';

      $d->{ext} = $ext;

      $d->{img} = sprintf(q{%s.%s},$d->{inum},$d->{ext});
  }

  $d->{img_file} = catfile($self->{img_root},$d->{img});

  return $self;
}

sub loop {
  my ($self) = @_;

  my @flines = @{$self->{flines} || []};

  foreach(@flines) {
    $self->{lnum}++; chomp;

    $self->{line} = $_;

    next if /^\s*%/;

    m/^\\ifcmt\s*$/g && do { $self->{is_cmt} = 1; next; };
    m/^\\fi\s*$/g && do { 
       $self->process_block;
       $self->{is_cmt} = undef; 
       next; 
    };

    next unless $self->{is_cmt};

    m/^\s*(local|global)\s*$/g && do { 
       $self->process_block;

       my $k = trim($1);

       $self->{'is_' . $k} = 1; 
       $self->{block} = $k;
    };

    m/^\s*(\w+)\s+(.*)$/g && do {
       my ($d, $locals, $globals) = @{$self}{qw(d locals globals)};

       my $k = trim($1);
       my $v = trim($2);

       if (grep { /^$k$/ } qw( pic doc ig ) ){
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
    
            print qq{try: curl} . "\n";
    
            my $url_s = $^O eq 'MSWin32' ? qq{"$url"} : qq{"$url"};
    
            my $cmd = qq{ $curl -o "$img_file" $url_s };
            my $x = qx{ $cmd 2>&1 };
            $self->debug(["Command:", $x]);
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

sub _fetch {
  my ($self) = @_;

  my $d = $self->{d};
  return $self unless $d && $d->{img_file};

  return $self if !$self->_reload && -e $d->{img_file};

  my $gi = $self->{gi};

  my $sec = $self->{sec};

  my @subs = $self->_subs_url({ 
     url      => $d->{url},
     img_file => $d->{img_file},
     sec      => $sec,
  });

  my @m; push @m,
     'x' x 50,
     'Try downloading picture:',
     '  proj:     ' . $self->{proj},
     '  sec:      ' . $sec,
     '  url:      ' . $d->{url},
     '  img:      ' . $d->{img},
     '  caption:  ' . ($d->{caption} || ''),
     ;

  print join("\n",@m) . "\n";

  $self->_reload && (-e $d->{img_file}) && do { rmtree $d->{img_file}; };

  while($self->_fetch_on){
     my $s  = shift @subs;
     my $ss = $s->();
  }

  my $dd = {
     url  => $d->{url},
     img  => $d->{img},
     sec  => $sec,
  };

  unless(-e $d->{img_file}){
     print qq{DOWNLOAD FAIL: } . $d->{img} . "\n";
     push @{$gi->{fail}}, $dd;
     return ;
  }else{
     print qq{DOWNLOAD SUCCESS: } . $d->{img} . "\n";
     push @{$gi->{ok}}, $dd;
  }

  my $itp = image_type($d->{img_file}) || {};
  my $iif = image_info($d->{img_file}) || {};

  my $media_type_str = $iif->{file_media_type} || '';
  my ($img_type) = ( $media_type_str =~ m{image\/(\w+)} );
        
  $d->{img_err} = $iif->{error};
  if ($d->{img_err}) {
     print qq{image_info FAIL: } . $d->{img} . "\n";
     print '  ' .  $d->{img_err} . "\n";
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

     if (grep { /^$d->{ext}$/ } qw(gif webp)) {
        my $img_jpg = sprintf(q{%s.%s},$d->{inum},'jpg');
        my $cmd = sprintf(q{convert %s %s},$d->{img_file}, $img_jpg);

        printf(q{Convert: %s => %s} . "\n", basename($d->{img_file}), $img_jpg);
        system("$cmd");
        my $img_file_jpg = catfile($self->{img_root},$img_jpg);
        if (-e $img_file_jpg) {
            print 'Convert OK' . "\n";
            rmtree $d->{img_file};
            $d->{img_file} = $img_file_jpg;
            $d->{img} = $img_jpg;
        }
     }
  }
  $d->{ext} = undef;

  print '=' x 50 . "\n";
  print qq{Final image location: } . basename($d->{img_file}) . "\n";
  print '=' x 50 . "\n";

  return 1;

}


1;
 

