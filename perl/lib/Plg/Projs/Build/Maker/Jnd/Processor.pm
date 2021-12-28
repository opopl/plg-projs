
package Plg::Projs::Build::Maker::Jnd::Processor;

use strict;
use warnings;

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Base::Arg qw(
  hash_inject
  hash_update
);

use Image::Info qw(
    image_info
    image_type
);

use Plg::Projs::Rgx qw(%rgx_map);

use String::Util qw(trim);

use Base::String qw(
  str_split
);

use Base::DB qw(
    dbh_select
    dbh_select_first
);

use Plg::Projs::Tex qw(
    texify 
);

use Base::List qw(
  uniq
);

use Data::Dumper qw(Dumper);

use base qw(
    Base::Obj
);

sub new
{
    my ($class, %opts) = @_;
    my $prc = bless (\%opts, ref ($class) || $class);

    $prc->init if $prc->can('init');

    return $prc;
}

sub init {
    my ($self) = @_;
    
    #$self->SUPER::init();
    #
    my $h = {
       d        => undef,
       d_author => undef,
       tab      => undef,

       dbh_img    => undef,
       dbfile_img => undef,

       img_width_default => 0.9,
       keys => [qw(url caption tags name)],

       jfile  => undef,
       jlines => [],
       nlines => [],

       img      => undef,
       img_path => undef,
       url      => undef,
       caption  => undef,

       is_cmt => undef,
       lnum => 0,

       root => undef,
       proj => undef,
       sec  => undef,

       # external instances:
       #
       # mkr => Plg::Projs::Build::Maker
       # prj => Plg::Projs::Prj
       mkr => undef,
       prj => undef,

    };
 
    hash_inject($self, $h);
    return $self;
}




sub tab_init {
  my $self = shift;

  $self->{tab} = {};

  my $h = {
      cols       => 2,
      align      => 'c',
      env        => 'tabular',
      i_col      => 1,
      i_row      => 1,
      fig_env    => 'figure',
      cap_list   => [],
      resizebox  => 0.9,
  };
  hash_inject($self->{tab}, $h);

  return $self;
}


sub _tab_start {
  my ($self) = @_;
  my $tab = $self->{tab};
  
  return () unless $tab;
  my @tex;

  push @tex, 
    $tab->{center} ? '\begin{center}%' : (),
    $tab->{resizebox} ? '\resizebox{'.$tab->{resizebox}.'\textwidth}{!}{%' : (),
    sprintf(q| \begin{%s}{*{%s}{%s}} |,@{$tab}{qw(env cols align)})
    ;

  return @tex;

}

sub _tab_end {
  my $self = shift;

  my $tab = $self->{tab};

  return () unless $tab;
  my @tex;

  my $env = $tab->{env};

  push @tex, 
    sprintf(q| \end{%s}|,$env),
    $tab->{resizebox} ? '}' : (),
    $tab->{center} ? '\end{center}' : (),
    ;

  return @tex;

}

sub _tex_caption_tab { 
  my ($self) = @_;

  my $tab = $self->{tab};
  return () unless $tab;

  my $c = $tab->{caption} || '';
  return () unless $c;

  my $i_cap = 0;
  my @caps;
    
  for(@{$tab->{cap_list}}){
     $i_cap++;
     push @caps, 
        sprintf('\textbf{(%s)} %s', $i_cap, @{$_}{qw(caption)});
  }
  my $c_long = join(" ", $c, @caps );

  my @c; push @c, sprintf(q| \caption[%s]{%s} |, $c, $c_long );
  return @c;
}

# _width <=> $get_width
sub _width {
  my ($self, $wd) = @_;
  my $w = $wd 
            // $self->_val_('d width') 
            // $self->_val_('tab width') 
            // $self->_val_('locals width') 
            // $self->{img_width_default};

  return $w;
}

sub _dict_update {
  my ($self, $dict, $k, $v) = @_;

  $dict ||= {};

  if (defined $dict->{$k}) {
     my $ka = '@' . $k;
     $dict->{$ka} ||= [ $dict->{$k} ];
     push @{$dict->{$ka}}, $v;
  }
  $dict->{$k} = $v;

  return $dict;
}

sub _wrapped {
  my ($self, $wrap, $position) = @_;

  return () unless $wrap;

  my @lines;
  #push @lines, map { '%' . $_ } split '\n' => Dumper($wrap);

  unless(ref $wrap) {
     local $_ = $wrap;

     /^\\(\w+)/ && do {
        if ($position eq 'start') {
          push @lines, $_ . '{';
        } elsif ($position eq 'end') {
          push @lines, '}';
        }
     };

     /^(\w+)(?:{(.*)}|)$/ && do {
        my $env = $1;
        if ($position eq 'start') {
          my $obr = $2 ? "{$2}" : '';
          push @lines, "\\begin{$env}$obr";
        } elsif ($position eq 'end') {
          push @lines, "\\end{$env}";
        }
     };
  }elsif(ref $wrap eq 'ARRAY'){
     foreach my $x (@$wrap) {
        my @w = $self->_wrapped($x, $position);
        if ($position eq 'start') {
          push @lines, @w;
        }elsif ($position eq 'end') {
          unshift @lines, @w;
        }
     }
  }
  for(@lines){
	  s/InsertBoxR.*\{/parpic[r]{/g;
	  s/InsertBoxL.*\{/parpic[l]{/g;
  }
  return @lines;
}


sub _cat_float {
  my ($self, $var) = @_;

  my $w;
  if (ref $var eq 'ARRAY') {
     for(@$var){
        $w += eval $_;
     }
  }elsif(!ref $var){
     $w = $var;
  }
  return $w;
}

sub _len2tex {
  my ($self, $len) = @_;

  my $tex = $len;
  for($len){
      /^(\d+(?:\.\d+|))$/ && do {
          $tex = qq{$len\\textwidth};
      };
      last;
  }
  return $tex;
}

sub _width_tex {
  my ($self, $wd) = @_;

  my $w = $self->_width($wd);

  $w = $self->_len2tex($w);

  return $w;
}

sub _tex_caption {
  my ($self, $caption) = @_;

  my $c = $self->_fig_skip ? 'captionof{figure}[]' : 'caption[]' ; 
  $caption ? ( sprintf(q| \%s{%s} |, $c, $caption ) ) : ();
}

sub _fig_env {
  my ($self) = @_;

  $self->_val_('tab fig_env') || $self->_val_('d fig_env') || 'figure';

}

sub _fig_start {
  my ($self) = @_;

  return () if $self->_fig_skip;

  my @s;
  my $fe = $self->_fig_env;
  for($fe){
      /^(figure)/ && do {
          push @s,
              q|\begin{figure}[ht] |,
              q|  \centering |;
          last;
      };

      /^(wrapfigure)/ && do {
          push @s, sprintf(q/\begin{%s}{R}{%s}/, $fe, $self->_width_tex );
          last;
      };

      /^(floatingfigure)/ && do {
          push @s, sprintf(q/\begin{%s}{%s}/, $fe, $self->_width_tex );

          last;
      };

      last;
   }

   return @s;
}

sub _fig_end {
  my ($self) = @_;

  my @e;
  return () if $self->_fig_skip;

  my $fe = $self->_fig_env;
  push @e, sprintf(q|\end{%s}|,$fe);

  return @e;
}

sub _fig_skip {
  my ($self) = @_;

  my $tab = $self->{tab};
  return 1 if $tab && $tab->{no_fig};

  my $t = $self->_val_('d type') || '';
  my $skip = (grep { /^$t$/ } qw(ig)) ? 1 : 0;

  return $skip;
}

sub match_author_id {
  my ($self, $author_id) = @_;

  return $self unless ( $self->{d_author} && defined $author_id );

  $self->{d_author}->{author_id} ||= [];

  push @{$self->{d_author}->{author_id}}, 
     str_split($author_id,{ 'sep' => ',', uniq => 1 });

  return $self;
}

sub match_author_begin {
  my ($self) = @_;

  $self->{d_author} = {};

  return $self;
}

sub match_author_end {
  my ($self) = @_;

  my $mkr = $self->{mkr};

  my $author_ids = $self->_val_('d_author author_id') || [];
  return $self unless @$author_ids;

  $author_ids = uniq($author_ids);

  foreach my $author_id (@$author_ids) {
     my $prj    = $mkr->{prj};
     my $author = $prj->_author_get({ author_id => $author_id });

     $author =~ s/\(/ \\textbraceleft /g;
     $author =~ s/\)/ \\textbraceright /g;

     push @{$self->{nlines}}, sprintf(q{\Pauthor{%s}}, $author) if $author;

     $self->{d_author} = undef;

  }

  return $self;
}

sub _opts_dict {
  my ($self, $opts_s) = @_;

  return unless defined $opts_s;

  my @opts = grep { length } map { defined ? trim($_) : () } split("," => $opts_s);

  return unless @opts;
  my $dict = {};

  for(@opts){
     my ($k, $v) = (/^([^=]+)(?:|=([^=]+))$/g);
     $k = trim($k);

     $dict->{$k} = defined $v ? trim($v) : 1;
  }

  return $dict;
}

sub match_tab_begin {
  my ($self, $opts_s) = @_;

  return $self unless defined $opts_s;

  $self->tab_init;

  hash_update(
    $self->{tab}, 
    $self->_opts_dict($opts_s)
  );

  my $tab = $self->{tab};
  $tab->{width} ||= ( $self->{img_width_default} / $self->{tab}->{cols} );
  
  push @{$self->{nlines}}, 
     $self->_fig_start, 
     $self->_tab_start;

  return $self;
}

sub match_tab_end {
  my ($self) = @_;

  my $tab = $self->{tab};

  push @{$self->{nlines}}, 
     $self->_tab_end, $self->_tex_caption_tab,
     $self->_fig_end,
     ;

  $self->{tab} = undef;

  return $self;
}

sub ldo_no_cmt {
  my ($self) = @_;

  local $_ = $self->{line};

  m/^\s*%%\s*\\ii\{(.*)\}\s*$/ && do {
     $self->{sec} = $1;
  };

  m/\@(pic|ig|doc)\{([^{}]+)\}/ && do {
     my $type = $1;
  };

  $self->{line} = $_;
  push @{$self->{nlines}}, $self->{line}; 

  return $self;
}

# push content of d => nlines
sub lpush_d {
  my ($self) = @_;
  
  my $d = $self->{d};
  return $self unless $d;

  push @{$self->{nlines}},$self->_d2tex;

  my $tab = $self->{tab};
  if ($tab) {
     my $i_col = $tab->{i_col};

     if ($d->{caption}) {
        push @{$tab->{cap_list}},
        { 
             i_col   => $tab->{i_col},
             i_row   => $tab->{i_row},
             caption => $d->{caption},
        }
        ;
     }

     my @s;
     if ($self->_tab_at_end) {

        push @s, q{\\\\};

        my @caps = map { ($_->{i_row} == $tab->{i_row}) ? ($_->{caption} || '') : () } @{$tab->{cap_list}};

        $tab->{i_col} = 1;
        $tab->{i_row}++;
     }else{
        push @s, q{&};
        $tab->{i_col}++;
     }
  
     push @{$self->{nlines}}, @s;
  }

  $self->{d} = undef;

  return $self;
}

sub _tab_at_end {
  my ($self) = @_;

  my $at_end = ( $self->_val_('tab i_col') == $self->_val_('tab cols') ) ? 1 : 0;
  return $at_end;
}

sub _param {
  my ($self, $key) = @_;

  my $d       = $self->{d};
  my $tab     = $self->{tab};
  my $locals  = $self->{locals};
  my $globals = $self->{globals};

}

sub _d2tex {
  my ($self) = @_;

  my $d = $self->{d};
  return () unless $d;

  my $mkr = $self->{mkr};
  my $dbh_img = $self->{dbh_img};

  my $tab = $self->{tab};


  my $w = {};
  for(qw( url name_uniq name )){
     if ($d->{$_}){
        $w->{$_}  = $d->{$_};
        last;
     }
  }

  my $dbh = $mkr->{dbh_img};
  my ($rows, $cols, $q, $p) = dbh_select({
     $dbh ? ( dbh => $dbh ) : (),
     #dbh => $mkr->{dbh_img},
     #dbfile => $self->{dbfile_img},
     q   => q{ SELECT * FROM imgs },
     p   => [],
     w   => $w,
  });

  my $url = $d->{url};
  unless (@$rows) {
     my @err;
     my $r = {    
         msg => q{ No image found in Database! },
         url => $url,
     };
     warn Dumper($r) . "\n";
     push @err, qq{%Image not found: $url };
     return @err;
  }

  my $rw = shift @$rows;
 
  my $img_path = sprintf(q{\imgroot/%s},$rw->{img});
 
  my $img_file = catfile($mkr->{img_root},$rw->{img});
  unless (-e $img_file) {
     my @err;

     my $r = {    
         msg => q{Image file not found!},
         img => $rw->{img},
         url => $d->{url},
     };
     warn Dumper($r) . "\n";
     push @err, qq{%Image exists in DB but not found in FS: $url };
     return @err;
  }

  my @tex;
  {
    my $iinfo = image_info($img_file);
    my ($w, $h) = map { $iinfo->{$_} } qw( height width );
    my $w2h = $h ? ($w*1.0)/$h : '';
    push @tex, '% w2h = ' . $w2h;
  }

  my $caption = $d->{caption};
  Plg::Projs::Tex::texify(\$caption) if $caption;

  my $wd = $d->{width} || $rw->{width_tex};

  my @o;
  push @o, 
    'keepaspectratio';

  unless($tab){
    push @o, 
      sprintf(q{ width=%s },$self->_width_tex($wd));
  }else{
    my $tab_width = $tab->{width};
    my $tab_height = $self->_val_('tab height') || $tab_width*0.9;
    my $locals = $self->{locals} || {};

    my $use_height =  ( $tab->{use_locals} ? $locals->{no_height} : 0 )
       || $d->{no_height} || $tab->{no_height} ? 0 : 1;

    my $width = ( $tab->{use_locals} ? $locals->{width} : 0 ) || 
                ( $tab->{use_d} ? $d->{width} : 0 ) || $tab_width;

    if($use_height) {
      push @o, sprintf(q{ height=%s }, $self->_len2tex($tab_height));
    }elsif($width){
      push @o, sprintf(q{ width=%s }, $self->_len2tex($width));
    }
  }

  if (my $rotate = $d->{rotate}) {
    #my $dict_rotate = opts_dict($rotate);
    push @o, $rotate;
  }

  my $o = join(",",@o);

  my (@ig, $ig_cmd); 
  $ig_cmd = sprintf(q|  \includegraphics[%s]{%s} |, $o, $img_path );

  push @ig, $ig_cmd;

  my $repeat = $d->{repeat};
  if ($repeat && $repeat =~ /^(\d+)$/) {
    my $times = $1;
    $times--;

    if ($times > 0) {
       push @ig, $ig_cmd for ( 1 .. $times );
    }
      
  }

  my $wrap = $d->{'@wrap'} || $d->{'wrap'};
  my $parbox = $self->_val_('tab parbox') || $d->{parbox};

  push @tex, $self->_wrapped($wrap,'start');

  unless($tab){
     push @tex,
        $self->_fig_start, # () if not figure
          $parbox ? sprintf('\parbox{%s}{%', $self->_len2tex($parbox) ) : (),
            @ig,
            $caption ? $self->_tex_caption($caption) : (),
            $d->{cap} ? sprintf('\begin{center}\figCapA{%s}\end{center}',$d->{cap}) : (),
          $parbox ? '}%' : (),
        $self->_fig_end,   # () if not figure
        ;
  }else{
     push @tex,
        sprintf('%% row: %s, col: %s ', @{$tab}{qw(i_row i_col)}),
        $parbox ? sprintf('\parbox{%s}{%', $self->_len2tex($parbox) ) : (),
          $caption ? ( sprintf(q|%% %s|, $caption )) : (),
          @ig,
          $d->{cap} ? sprintf('\begin{center}\figCapA{%s}\end{center}',$d->{cap}) : (),
        $parbox ? '}%' : (),
        ;
  }

  push @tex, $self->_wrapped($wrap,'end');

  return @tex;
}

sub f_read {
  my ($self, $ref) = @_;

  $ref ||= {};

  my $file = $ref->{file} || $self->{jfile};

  push @{$self->{jlines}}, read_file $file;

  return $self;
}

sub f_write {
  my ($self, $ref) = @_;

  my $mkr = $self->{mkr};

  $ref ||= {};

  my $file = $ref->{file} || $self->{jfile};

  unshift @{$self->{nlines}},
        ' ',
        sprintf(q{\def\imgroot{%s}}, $mkr->{img_root_unix} ),
        ' '
        ;

  write_file($file,join("\n",@{$self->{nlines}}) . "\n");

  return $self;
}

sub _macro_fbicon {
  my ($self, $arg, $opts_s) = @_;
}

sub _macro_igg {
  my ($self, $igname, $opts_s) = @_;

  my @ignames = 
     grep { !/^(\d+)$/ }
     split ' ' => $igname;

  if(@ignames > 1){
     my ($tex, @tex);
     for(@ignames){
        push @tex, $self->_macro_igg($_,$opts_s);
     }
     $tex = join("\n",@tex);
     return $tex;
  }

  $igname = trim($igname);

  $self->{d} = { 
     name => $igname, 
     type => 'ig' 
  };

  hash_update(
     $self->{d},
     $self->_opts_dict($opts_s)
  );

  my ($tex, @tex);
  push @tex, $self->_d2tex;
  $tex = join("\n",@tex);

  $self->{d} = undef;
  return $tex;
}

sub loop {
  my ($self) = @_;

  my @jlines = @{$self->{jlines} || []};

  foreach(@jlines) {
    $self->{lnum}++; chomp;

    #s/\@igg\{([^{}]*)\}(?:\{([^{}]*)\}|)/$self->_macro_igg($1,$2)/ge;
    s/$rgx_map{jnd}{macros}{igg}/$self->_macro_igg($1,$2)/ge;

    $self->{line} = $_;

###m_\ifcmt
    m/^\\ifcmt\s*$/g && do { 
        $self->{is_cmt} = 1; 
        $self->{locals} = {};
        #push @{$self->{nlines}},'{';
        next; 
    };
###m_\fi
    m/^\\fi\s*$/g && do { 
       $self->lpush_d;
       $self->{$_} = undef for(qw(is_cmt locals));  
       #push @{$self->{nlines}},'}';
       next; 
    };

    m/^\s*%/ && do { push @{$self->{nlines}},$_; next; };

###m_block_end
    if ($self->{is_cmt}) {
       m/^\s*(\w+)/ && do { 
          my $k = $1;
          my @block_end = qw( 
            tex tex_start 
            tab_begin tab_end
            pic ig doc
          );
          if ( grep { /^$k$/ } @block_end ) {
             $self->lpush_d;
          }
       };
    }else{
       $self->ldo_no_cmt;
       next;
    }

###m_tex
    m/^\s*tex\s+(.*)$/g && do {
        my $tex = trim($1);
        push @{$self->{nlines}},$tex; 
        next;
    };

###m_tex_start
    m/^\s*tex_start\s+(.*)$/g && do {
        $self->{is_tex} = 1;
        next;
    };

###m_tex_end
    m/^\s*tex_end\s+(.*)$/g && do {
        $self->{is_tex} = undef;
        next;
    };

###m_author
    m/^\s*author_end\s*$/g && do { $self->match_author_end; next; };
    m/^\s*author_begin\s*$/g && do { $self->match_author_begin; next; };

    m/^\s*author_id\s*(.*)\s*$/g && do { $self->match_author_id($1); next; };
   
    m/^\s*tab_begin\b(.*)/g && do { $self->match_tab_begin($1); next; };
    m/^\s*tab_end\s*$/g && do { $self->match_tab_end; next; };

###m_pic@
    m/^\s*(pic|doc|ig)@(.*)$/g && do { 
       my $v;
       $v = trim($2) if $2;

       next unless $v;

       my $opts = $self->_opts_dict($v);   
       next unless $opts;

       $self->{d} = { type => $1 };

       hash_update( $self->{d}, $opts);

       next;
    };

###m_pic
    m/^\s*(pic|doc|ig)(?:\s+(.*)|\s*)$/g && do { 
       my $v;
       $v = trim($2) if $2;

       $self->{d} = { type => $1 };

       $self->{d}->{url} = $v if $v;

       next;
    };

###m_@keyword
    m/^\s*(?:@|)(?<key>\w+)\s+(?<value>.*)$/g && do { 
      my $k = $+{'key'};
      my $v = trim($+{'value'});

      my ($d, $tab, $locals) = @{$self}{qw( d tab locals )};
      if($d){
         $self->_dict_update($d, $k => $v);

      }elsif($tab){
         $self->_dict_update($tab, $k => $v);

      # variables within ifcmt ... fi block
      }elsif($locals){
         $self->_dict_update($locals, $k => $v);
      }

      next;
    };

   }

  return $self;

}

1;
 

