
package Plg::Projs::Build::Maker::Jnd::Processor;

use strict;
use warnings;

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Base::Arg qw(
  hash_inject
  hash_update
);

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

       mkr => undef,

    };
 
    hash_inject($self, $h);
    return $self;
}


sub _tab_end {
  my $self = shift;

  my $env = $self->_val_('tab env');
  $env ? sprintf(q| \end{%s}|,$env) : '';
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
  };
  hash_inject($self->{tab}, $h);

  return $self;
}


sub _tab_start {
  my ($self) = @_;
  my $tab = $self->{tab};

  ($tab) ? sprintf(q| \begin{%s}{*{%s}{%s}} |,@{$tab}{qw(env cols align)}) : '';
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
  my $w = $wd || $self->_val_('d width') || $self->_val_('tab width') || $self->{img_width_default};

  return $w;
}

sub _width_tex {
  my ($self, $wd) = @_;

  my $w = $self->_width($wd);
  for($w){
      /^(\d+(?:|\.\d+))$/ && do {
          $w = qq{$w\\textwidth};
      };
      last;
  }
  return $w;
}

sub _tex_caption {
  my ($self, $caption) = @_;

  $caption ? ( sprintf(q| \caption{%s} |, $caption ) ) : ();
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


sub match_tab_begin {
  my ($self, $opts_s) = @_;

  return $self unless defined $opts_s;

  $self->tab_init;

  my @tab_opts = grep { length } map { defined ? trim($_) : () } split("," => $opts_s);
  for(@tab_opts){
     my ($k, $v) = (/([^=]+)=([^=]+)/g);
     $self->{tab}->{$k} = $v;
  }

  $self->{tab}->{width} ||= ( $self->{img_width_default} / $self->{tab}->{cols} );
  
  push @{$self->{nlines}}, 
     $self->_fig_start, 
     $self->_tab_start;

  return $self;
}

sub match_tab_end {
  my ($self) = @_;

  $self->lpush_d;

  push @{$self->{nlines}}, 
     $self->_tab_end, $self->_tex_caption_tab,
     $self->_fig_end;

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

sub _d2tex {
  my ($self) = @_;

  my $mkr = $self->{mkr};

  my $d = $self->{d};
  return () unless $d;

  my $tab = $self->{tab};

  my @tex;

  my $w = {};
  for(qw( url name_uniq name )){
     if ($d->{$_}){
        $w->{$_}  = $d->{$_};
        last;
     }
  }

  my ($rows, $cols, $q, $p) = dbh_select({
     dbh => $mkr->{dbh_img},
     q   => q{ SELECT * FROM imgs },
     p   => [],
     w   => $w,
  });

  unless (@$rows) {
     my $url = $d->{url};
     my $r = {    
         msg => q{ No image found in Database! },
         url => $url,
     };
     warn Dumper($r) . "\n";
     push @tex, qq{%Image not found: $url };
     return @tex;
  }

  my $rw = shift @$rows;
 
  my $img_path = sprintf(q{\imgroot/%s},$rw->{img});
 
  my $img_file = catfile($mkr->{img_root},$rw->{img});
  unless (-e $img_file) {
     my $r = {    
         msg => q{Image file not found!},
         img => $rw->{img},
         url => $d->{url},
     };
     warn Dumper($r) . "\n";
     return @tex;
  }

  my $caption = $d->{caption};
  texify(\$caption) if $caption;

  my $wd = $d->{width} || $rw->{width_tex};

  my $o  = sprintf(q{ width=%s },$self->_width_tex($wd));

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

  unless($tab){
     push @tex,
        $self->_fig_start, 
        @ig,
        $caption ? $self->_tex_caption($caption) : (),
        $self->_fig_end;
  }else{
     push @tex,
        sprintf('%% row: %s, col: %s ', @{$tab}{qw(i_row i_col)}),
        $caption ? ( sprintf(q|%% %s|, $caption )) : (),
        @ig;
  }


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

sub loop {
  my ($self) = @_;

  my $mkr = $self->{mkr};

  my @jlines = @{$self->{jlines} || []};

  foreach(@jlines) {
    $self->{lnum}++; chomp;

    $self->{line} = $_;

###m_\ifcmt
    m/^\\ifcmt\s*$/g && do { $self->{is_cmt} = 1; next; };
###m_\fi
    m/^\\fi\s*$/g && do { 
       $self->lpush_d;
       $self->{is_cmt} = 0; 
       next; 
    };

    unless($self->{is_cmt}){ 
       $self->ldo_no_cmt;
       next;
    }

    m/^\s*%/ && do { push @{$self->{nlines}},$_; next; };

    m/^\s*tex\s+(.*)$/g && do {
        my $tex = trim($1);
        push @{$self->{nlines}},$tex; next;
    };

    m/^\s*author_end\s*$/g && do { $self->match_author_end; next; };
    m/^\s*author_begin\s*$/g && do { $self->match_author_begin; next; };

    m/^\s*author_id\s*(.*)\s*$/g && do { $self->match_author_id($1); next; };
   
    m/^\s*tab_begin\b(.*)/g && do { $self->match_tab_begin($1); next; };
    m/^\s*tab_end\s*$/g && do { $self->match_tab_end; next; };

    m/^\s*(pic|doc|ig)@(.*)$/g && do { 
       my $v;
       $v = trim($2) if $2;

       $self->lpush_d;

       next unless $v;

       my @opts = grep { length } map { defined ? trim($_) : () } split("," => $v);
       next unless @opts;

       $self->{d} = { type => $1 };

       for(@opts){
         my ($k, $v) = (/([^=]+)=([^=]+)/g);

         $k = trim($k);
         $v = trim($v);

         $self->{d}->{$k} = $v;
       }

       next;
    };

    m/^\s*(pic|doc|ig)(?:\s+(.*)|\s*)$/g && do { 
       my $v;
       $v = trim($2) if $2;

       $self->lpush_d;

       $self->{d} = { type => $1 };

       $self->{d}->{url} = $v if $v;

       next;
    };

    m/^\s*(\w+)\s+(.*)$/g && do { 
      my $v = trim($2);

      if($self->{d}){
         $self->{d}->{$1} = $v;

      }elsif($self->{tab}){
         $self->{tab}->{$1} = $v;
      }

      next;
    };

   }

  return $self;

}

1;
 

