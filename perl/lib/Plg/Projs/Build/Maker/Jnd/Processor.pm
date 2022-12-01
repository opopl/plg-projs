
package Plg::Projs::Build::Maker::Jnd::Processor;

use utf8;

use strict;
use warnings;

# binmode STDOUT, ":encoding(UTF-8)";
# use open ':std', ':encoding(UTF-8)'; 
#
use Encode;

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Plg::Projs::GetImg;

use YAML qw( LoadFile Load Dump DumpFile );
use File::Copy qw(copy move);
use File::Path qw(mkpath rmtree);

use Base::Arg qw(
  hash_inject
  hash_update

  dict_update

  opts2dict
  d2dict
  d2list
  dict_update_kv
);

#use Date::Manip;
use DateTime;
use DateTime::Locale;

use Plg::Projs::Map qw(
  %tex_syms
);

use Image::Info qw(
    image_info
    image_type
);

use Plg::Projs::Rgx qw(%rgx_map);

use String::Util qw(trim);

use Base::String qw(
  str_split
  str_split_trim
);

use Base::DB qw(
    dbh_select
    dbh_select_first
);

use Plg::Projs::Tex qw(
    texify 
    escape_latex
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

sub ctl_end {
    my ($self, $key) = @_;

    my $kv = $self->{key_val};
    my $d  = $self->{d};

    $d->{$key} = [@$kv] if $d && $kv && @$kv;

    $self->{is_key} = undef;
    $self->{key_val} = undef;

    return $self;
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
       is_caption => undef,
       lnum => 0,

       # see igc
       width_by_igc => 0.7,

       # m_@ctl
       is_key => undef,
       key_val => undef,

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

sub tab_store_wd {
  my ($self) = @_;

  my $tab = $self->{tab};
  return $self unless $tab;

  my $i_row = $tab->{i_row};
  return $self unless defined $i_row;

  # row, col index within loop
  my ($jr, $jc);

  # row's total width
  my ($wd_sum);

  # updated cell's width
  my $wdn;

  my $pat_sl = qr/^\\setlength\{\\cellWidth\}\{(.*)\\textwidth\}\s*$/;
  my $pat_rc = qr/^%tab row: (\d+), col: (\d+)/;
  my $reduce = $tab->{reduce};

  for(@{$tab->{store}}){
    if (/$pat_rc/) {
      ($jr, $jc) = ( $1, $2 );
    }

    next unless defined $jr;
    next unless defined $jc;

    next unless $jr == $i_row;

    $wd_sum = $tab->{rows}->{$jr}->{wd_sum};

    my ($wd) = ( /$pat_sl/ );
    if (defined $wd) {
      if (defined $wd_sum) {
        $wdn = $wd / $wd_sum;
        $wdn *= $reduce if $reduce;
        s/\Q$wd\E/$wdn/g;
      }
    }
  }

  return $self;
}

sub tab_rws_sum_wd {
  my ($self) = @_;

  my $tab = $self->{tab};
  return $self unless $tab;

  my $i_row //= $tab->{i_row};
  return $self unless defined $i_row;

  my $cols = $tab->{cols};

  my $rw_cells = $tab->{cells}->{$i_row};

  my $sum = 0.0;
  foreach my $i (1 .. $cols) {
    my $cl = $rw_cells->{$i};
    my $wd = $cl->{wd};
    $sum += $wd;
  }

  $tab->{rows}->{$i_row}->{wd_sum} = $sum;

  return $self;
}

sub tab_cell_update {
  my ($self, $update, $i_row, $i_col) = @_;

  my $tab = $self->{tab};
  return $self unless $tab;

  $update ||= {};

  $i_row //= $tab->{i_row};
  $i_col //= $tab->{i_col};

  return $self unless defined $i_row;
  return $self unless defined $i_col;

  $tab->{cells}->{$i_row}->{$i_col} ||= {};
  my $cell = $tab->{cells}->{$i_row}->{$i_col};

  while(my($k,$v)=each %$update){
     $cell->{$k} = $v;
  }

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
      resizebox  => 0,
      minipage   => 0,
      # table caption
      caption    => '',
      store      => [],
      cells      => {},
      rws        => {},
      reduce     => 0.9,
  };
  hash_inject($self->{tab}, $h);

  return $self;
}


sub _tab_start {
  my ($self) = @_;
  my $tab = $self->{tab};
  
  return () unless $tab;
  my @tex;

  my %w = ( 
      resizebox => $self->_len2tex($tab->{resizebox}),
      minipage  => $self->_len2tex($tab->{minipage}),
  );

  push @tex, 
    $tab->{center} ? '\begin{center}%' : (),
    $tab->{resizebox} ? sprintf('\resizebox{%s}{!}{%% start_resizebox',$w{resizebox}) : (),
    $tab->{minipage} ? sprintf('\begin{minipage}{%s}%%',$w{minipage}) : (),
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
    $tab->{caption} ? sprintf('\captionof{table}{%s}%%',$tab->{caption}) : (),
    $tab->{minipage} ? '\end{minipage}' : (),
    $tab->{resizebox} ? '}% fin_resizebox' : (),
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

sub _expand_igg {
  my ($self, $line, $ref) = @_;

  $ref ||= {};

  local $_ = $line;

  #s/\@igg\{([^{}]*)\}(?:\{([^{}]*)\}|)/$self->_macro_igg($1,$2)/ge;
  s/$rgx_map{jnd}{macros}{igg}/$self->_macro_igg($1,$2,$ref)/ge;

  return $_;
};


# expand key value pair
sub _expand_kv {
  my ($self, $key, $val) = @_;

  while(1){
    local $_ = $key;

    /^caption$/ && do {
      $val =~ s/\@label/\\figLabel/g;
      last;
    };
    last;
  };

  return $val;
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

  return '' unless defined $len;

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
  my ($self, $d, $caption) = @_;

  my $tab = $self->{tab};
  $d ||= $self->{d};

  my $c = $self->_fig_skip($d) ? 'captionof{figure}[]' : 'caption[]' ;
  #$caption ? ( sprintf(q| \%s{%s} |, $c, ( $tab ? '\Large ' : '' ) . $caption ) ) : ();
  $caption ? ( sprintf(q| \%s{%s} |, $c, $caption ) ) : ();
}

sub _fig_env {
  my ($self, $d) = @_;

  $d ||= $self->{d};

  $self->_val_('tab fig_env') || ( $d ? $d->{fig_env} : '' )  || 'figure';

}

sub _fig_start {
  my ($self, $d) = @_;

  $d ||= $self->{d};

  return () if $self->_fig_skip($d);

  my @s;
  my $fe = $self->_fig_env($d);
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
  my ($self, $d) = @_;

  $d ||= $self->{d};

  my @e;
  return () if $self->_fig_skip($d);

  my $fe = $self->_fig_env($d);
  push @e, sprintf(q|\end{%s}|,$fe);

  return @e;
}

sub _fig_skip {
  my ($self, $d) = @_;

  $d ||= $self->{d};

  my $tab     = $self->{tab};
  my $globals = $self->{globals};

  #my $ok = 1;
  #$ok &&= $tab && $tab->{no_fig};

  return 1 if $tab && $tab->{no_fig};
  return 1 if $globals && ( $globals->{no_fig} || $globals->{mlc} );

  my $t = $d ? $d->{type} : '' ;
  my $skip = (grep { /^$t$/ } qw(pic)) ? 0 : 1;

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


sub match_yaml_begin {
  my ($self) = @_;

  $self->{d_yaml} ||= {};

  $self->{yaml} = [];
  $self->{is_yaml} = 1;

  return $self;
}

sub match_yaml_end {
  my ($self) = @_;

  my $ystr = join("\n",@{$self->{yaml} || [] });
  my $ydata = Load($ystr);
  delete $self->{$_} for(qw(is_yaml yaml));

  hash_update( $self->{d_yaml}, $ydata);
  $self->{r_sec} = $self->{d_yaml}->{r_sec};

  return $self;
}

sub match_author_begin {
  my ($self) = @_;

  $self->{d_author} = {};

  return $self;
}

sub _tex_author {
  my ($self, $author_id) = @_;

  my @tex;
  my $mkr = $self->{mkr};

  my @ids = (!ref $author_id) ? str_split($author_id,{ 'sep' => ',', uniq => 1 }) : @$author_id;
  foreach my $id (@ids) {
     my $prj    = $mkr->{prj};
     my $author = $prj->_author_get({ author_id => $id });

     next unless $author;

     while(my($k,$v)=each %tex_syms){
        $author =~ s/\Q$k\E/$v /g;
     }
     Plg::Projs::Tex::texify(\$author);

     push @tex, sprintf(q{\Pauthor{%s}}, $author);
  }

  return @tex;
}

sub match_author_end {
  my ($self) = @_;

  my $mkr = $self->{mkr};

  my $author_ids = $self->_val_('d_author author_id') || [];
  return $self unless @$author_ids;

  $author_ids = uniq($author_ids);
 
  push @{$self->{nlines}}, $self->_tex_author($author_ids);

  $self->{d_author} = undef;

  return $self;
}

sub _opts_dict {
  my ($self, $opts_s) = @_;

  return unless defined $opts_s;

  my @opts = grep { length $_ } map { defined $_ ? trim($_) : () } split("," => $opts_s);

  return unless @opts;
  my $dict = {};

  for(@opts){
     my ($k, $v) = (/^([^=]+)(?:|=([^=]+))$/g);
     $k = trim($k);

     $dict->{$k} = defined $v ? trim($v) : 1;
  }

  return $dict;
}

sub match_caption_begin {
  my ($self,$opts_s) = @_;

  my $obj = $self->{d} || $self->{tab};
  return $self unless $obj;

  $self->{is_caption} = 1;

  return $self;
}

sub match_caption_end {
  my ($self) = @_;

  my $obj = $self->{d} || $self->{tab};
  return $self unless $obj;

  $self->{is_caption} = undef;

  return $self;
}

sub match_tab_begin {
  my ($self, $opts_s) = @_;

  return $self unless defined $opts_s;

  my $globals = $self->{globals} || {};
  return $self if $globals->{mlc};

  $self->tab_init;

  if (ref $opts_s eq 'HASH') {
    hash_update( $self->{tab}, $opts_s );
  }elsif(!ref $opts_s){
    hash_update( $self->{tab}, $self->_opts_dict($opts_s) );
  }

  my $tab = $self->{tab};
  my $tab_cols = $tab->{cols};
  $tab->{width} ||= ( $self->{img_width_default} / $tab_cols );
  
  return $self;
}

sub match_tab_end {
  my ($self) = @_;

  my $globals = $self->{globals} || {};
  return $self if $globals->{mlc};

  my $tab = $self->{tab};

  push @{$tab->{store}},
     $self->_tab_end,
     #$self->_tex_caption_tab,
     $self->_fig_end,
     ;

  push @{$self->{nlines}}, @{$tab->{store}};

  $self->{tab} = undef;

  return $self;
}

sub ldo_no_cmt {
  my ($self) = @_;

  my $mkr  = $self->{mkr};
  my $pats = $mkr->_pats;

  local $_ = $self->{line};

  my $ok = 1;

  my $r_sec     = $self->{r_sec} || {};
  my $url       = $r_sec->{url} || '';
  my $sec       = $r_sec->{sec} || '';
  my $author_id = $r_sec->{author_id} || '';
  my $date      = $r_sec->{date} || '';

  my ($date_s, @date);
  my $date_fmt = "%d %B %Y, %A";

  if ($date =~ /$pats->{date}/){
#    my $dt = Date::Manip::Date->new;
    #$dt->config('Language' => 'russian');
    ##$dt->config('Language' => 'ukrainian');
    #$dt->set('date',\@date);
    #$date_s = eval { $dt->printf("%d %B %Y, %A"); };
    #
    #push @date, @+{qw(year month day)}, qw( 0 0 0 );
    my %hms = map { $_ => 0 } qw( hour minute second );
    my $dt = DateTime->new( %+, %hms, 'locale' => 'uk' );
    $date_s = $dt->strftime($date_fmt);
  }

  my (@push, @top);
  while (1) {
    $_ = $self->_expand_igg($_);
  
    m/^\s*%%\s*\\ii\{(.*)\}\s*$/ && do {
       $self->{sec_info} = {};
       $self->{sec_info}->{sec} =  $1;

       last;
    };

    m/$pats->{label_sec}/ && do {
       my $m_sec = trim($1);
       $ok = 0 if $m_sec eq $sec;

       last;
    };

    #$DB::single = 1 if /subsection/;

    m/$pats->{sect}/ && do {
       my $seccmd = $1;
       $self->{sec_info}->{title} =  $1;

       my $lb = sprintf(q{\label{sec:%s}},$sec);
       $self->{sec_info}->{label} = 1;
       push @push, $lb;
       if($seccmd eq 'subsection'){
           push @top, sprintf('\ifdefined\HCode\NextFile{%s.html}\fi',$sec);

           push @push, (
             $url    ? sprintf(q{\Purl{%s}},$url) : (),
             $date_s ? sprintf(q{\Pdate{%s}},$date_s) : (),
             $self->_tex_author($author_id) 
           )
           ;
       }
       # $_ becomes undef for unknown reason in limited cases
       $_ = $self->{line} unless defined;
       last;
    };
  
    m/\@(pic|ig|doc)\{([^{}]+)\}/ && do {
       my $type = $1;
       last;
    };
  
    m/^\s*\\begin\{multicols\}\{(\d+)\}/g && do {
      $self->{multicols} = {
         cols => $1,
      };
      last;
    };
  
    m/^\s*\\end\{multicols\}/g && do {
      $self->{multicols} = undef;
      last;
    };
  
    if ($url) {
       /^\s*\\Purl\Q{$url}\E/ && do { $ok = 0; last; };
    }

    last;
  }

  if ($ok) {

    $self->{line} = $_;
    unshift @push, @top, $_;

    for(@push){
       # variation selector 16
       s/\N{U+FE0F}//g;

       # Combining Breve
       #s/\N{U+0306}//g;
       s/\x{0438}\x{0306}/й/g;

       s/\N{U+02BC}/'/g;

       #s/«([^«»]+)»/\\enquote{$1}/g;
       s/«([^«»]+)»/\"$1\"/g;

       # ≤
       s/\N{U+2264}/\$\\le\$/g;

       s/\N{U+1FAE1}/+/g;

       # georgian
       s/\N{U+10E1}/\\hcode{&\\#x10E1;}/g;
       s/\N{U+10D0}/\\hcode{&\\#x10D0;}/g;
       s/\N{U+10E5}/\\hcode{&\\#x10E5;}/g;
       s/\N{U+10E0}/\\hcode{&\\#x10E0;}/g;
       s/\N{U+10D7}/\\hcode{&\\#x10D7;}/g; # თ
       s/\N{U+10D5}/\\hcode{&\\#x10D5;}/g; # ვ
       s/\N{U+10D4}/\\hcode{&\\#x10D4;}/g; # ე
       s/\N{U+10DA}/\\hcode{&\\#x10DA;}/g; # ლ 
       s/\N{U+10DD}/\\hcode{&\\#x10DD;}/g; # ო
       s/\N{U+10E4}/\\hcode{&\\#x10E4;}/g; # ფ
       s/\N{U+10E2}/\\hcode{&\\#x10E2;}/g; # ტ
    }
    push @{$self->{nlines}}, @push;

###unicode_U+FE0F
    #$DB::single = 1 if /\N{U+FE0F}/;
    #$DB::single = 1 if grep { /\N{U+0306}/ } @push;
    #$DB::single = 1 if grep { /\\HCode/ } @push;
  }

  return $self;
}

sub lpush_tab_start {
  my ($self) = @_;

  my $tab = $self->{tab};
  return $self unless $tab && !$tab->{started};

  #push @{$self->{nlines}},
     #$self->_fig_start,
     #$self->_tab_start;

  push @{$tab->{store}},
     $self->_fig_start,
     $self->_tab_start;

  $tab->{started} = 1;

  return $self;
}

sub lpush_tab_end {
  my ($self) = @_;

  my $tab = $self->{tab};
  return $self unless $tab && $tab->{started};

  push @{$tab->{store}},
     $self->_tab_end,
     #$self->_tex_caption_tab,
     $self->_fig_end,
     ;

  return $self;
}

sub globals_update {
  my ($self, %update) = @_;

  $self->{globals} ||= {};
  my $globals = $self->{globals};

  UPDATE: while(my($k, $v)=each %update){

    for($k){
       /^mlc$/ && do {
          if ($v) {
            # end previous multicolumn
            if ($globals->{mlc}) {
              push @{$self->{nlines}}, q{\end{multicols}};
            }
            push @{$self->{nlines}},
                q{\raggedcolumns},
                sprintf(q{\begin{multicols}{%s}}, $v),
                q{\setlength{\parindent}{0pt}},
                ;
            $self->{multicols} = {
               cols => $v,
            };
          }else{
            $self->{multicols} = undef;
            delete $globals->{mlc};
            push @{$self->{nlines}}, q{\end{multicols}};
            next UPDATE;
          }

          last;
       };
     }

     dict_update_kv($globals, $k, $v);
  }

  return $self;
}

# push content of d => nlines (no tab), tab store (if tab)
sub lpush_d {
  my ($self, $d, $tab) = @_;

  my $d_custom = 1 if $d;
  $d ||= $self->{d};
  return $self unless $d;

  $tab ||= $self->{tab};

  my @d_tex = $self->_d2tex($d, $tab);
  if ($tab) {
    push @{$tab->{store}}, @d_tex;
  }else{
    push @{$self->{nlines}}, @d_tex;
  }

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
        $self->tab_rws_sum_wd;
        $self->tab_store_wd;

        push @s, q{\\\\};

        my @caps = map { ($_->{i_row} == $tab->{i_row}) ? ($_->{caption} || '') : () } @{$tab->{cap_list}};

        $tab->{i_col} = 1;
        $tab->{i_row}++;
     }else{
        push @s, q{&};
        $tab->{i_col}++;
     }
  
     #push @{$self->{nlines}}, @s;
     push @{$tab->{store}},@s;
  }

  $self->{d} = undef unless $d_custom;

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

sub _d_db_data {
  my ($self, $d) = @_;

  $d ||= $self->{d};
  return () unless $d;

  my $mkr   = $self->{mkr};
  my $r_sec = $self->{r_sec} || {};
  my $sec   = $r_sec->{sec};

  my $w = {};
  for(qw( url name_uniq name )){
     if ($d->{$_}){
        $w->{$_}  = $d->{$_};
        last;
     }
  }

  my $dbh = $mkr->{dbh_img};

  my ($img_file, $img_path, $rw, @err);

  while(1){
    my ($rows, $cols, $q, $p) = dbh_select({
       $dbh ? ( dbh => $dbh ) : (),
       #dbfile => $self->{dbfile_img},
       q   => q{ SELECT * FROM imgs },
       p   => [],
       w   => $w,
    });

    my $url = $d->{url};
    unless (@$rows) {
       $DB::single = 1 unless $url;
       my $r = {
           msg => q{ No image found in Database! },
           url   => $url,
           sec   => $sec,
           where => $w,
           line  => $self->{line},
       };
       warn Dumper($r) . "\n";
       push @err, qq{%Image not found: $url };
       last;
    }

    $rw = shift @$rows;

    # latex representation of the image file path
    $img_path = $mkr->{box} ? join("/" => 'imgs', $rw->{img}) : sprintf(q{\imgroot/%s},$rw->{img});

    # filesystem image file path
    $img_file = catfile($mkr->{img_root},$rw->{img});

    unless (-e $img_file) {
       my $r = {
           msg => q{Image file not found!},
           img => $rw->{img},
           url => $d->{url},
       };
       warn Dumper($r) . "\n";
       push @err, qq{%Image exists in DB but not found in FS: $url };
       last;
    }

    if ($mkr->{box}) {
       $mkr->{img_dir} ||= catfile($mkr->{src_dir},qw(imgs));
       mkpath $mkr->{img_dir} unless -d $mkr->{img_dir};
       my $img_file_box = catfile($mkr->{img_dir}, $rw->{img});
       copy($img_file, $img_file_box) unless -e $img_file_box;
    }

    last;
  }

  my $r = {
     img_file => $img_file,
     img_path => $img_path,
     rw       => $rw,
  };
  $r->{err} = [@err] if @err;

  return $r;
}

sub _d2tex_import {
  my ($self, $d) = @_;
  $d ||= $self->{d};
  return () unless $d && $d->{type} eq 'import';

  my ($mkr, $globals) = @{$self}{qw( mkr globals )};
  $globals ||= {};
  
  my $opts_import = $globals->{'opts_import'};

  #my $tab_opts  = $d->{tab} || '';

  my @tags_a = d2list($d,'tags');

  my $limit = $d->{limit} || 0;

  my $d_yaml = $self->{d_yaml} || {};
  my $r_sec  = $d_yaml->{r_sec} || {};
  my ($sec, $rootid, $parent) = @{$r_sec}{qw( sec rootid parent )};

  my ($proj, $root) = @{$self}{qw( proj root )};
  my $img_root = $mkr->{img_root};

  my $imgman = Plg::Projs::GetImg->new(
     skip_get_opt => 1,
     img_root => $img_root,
     sec    => $sec,
     proj   => $proj,
     root   => $root,
     rootid => $rootid,
  );

  my $w = d2dict($d,'where') || {};
  while( my($k,$v) = each %$w ){
     if ($k eq 'proj') {
        $v =~ s/\@this/$proj/g;
     } elsif ($k eq 'sec') {
        (my $sec_minus = $sec) =~ s/\.\w+$//g;
        $v =~ s/\@this\.minus/$sec_minus/g;
        $v =~ s/\@this/$sec/g;
     }
     $w->{$k} = $v;
  }

  my $imgs = $imgman->_db_imgs({
      tags => { and => \@tags_a },
      fields => [qw( url name_orig caption )],
      mode => 'rows',
      where => $w,
      limit => $limit
  });

  my $tab_dict = d2dict($d, 'tab');
  my $cols = ($tab_dict->{cols} || 1) if $tab_dict;

  my @tx;
  my $tab;
  my $n_imgs = scalar @$imgs;

  $tab_dict = undef if $n_imgs == 1;

  my $j = 0;
  foreach my $img (@$imgs) {
     $j++;

     if ($tab_dict) {
        if($j % $cols == 1){
            $self
              ->match_tab_begin($tab_dict)
              ->lpush_tab_start;
            $tab = $self->{tab};
        }
     }

     my ($url, $name_orig, $caption) = @{$img}{qw(url name_orig caption)};
     $caption ||= $name_orig;

     $caption = undef if ($tab && $tab->{no_caption});

     my $du = { 
         url     => $url,
         type    => 'ig',
         caption => $caption,
     };
     if ($tab_dict){
        $self->lpush_d($du);
     }else{
        $du->{width} = $d->{width} || 0.8;
        push @tx, $self->_d2tex($du), '';
     }

     if ($tab_dict) {
         if($j % $cols == 0 || $j == $n_imgs){
             $self->lpush_tab_end;
             push @tx, @{$tab->{store} || []};
             $self->{tab} = undef;
         }
     }
  }

  return @tx;
}

sub _d2tex {
  my ($self, $d, $tab) = @_;

  my $mkr = $self->{mkr};

  $d ||= $self->{d};
  $tab ||= $self->{tab};

  return () unless $d;

  return $self->_d2tex_import($d) if $d->{type} eq 'import';

  my ($locals, $globals) = @{$self}{qw( locals globals )};

  my $d_db = $self->_d_db_data($d);
  my ($img_file, $img_path, $rw)  = @{$d_db}{qw( img_file img_path rw )};

  unless ($img_file && $img_path) {
    my $err = $d_db->{err} || [];
    return  @$err;
    #push @err, 
      #'image file not found ',
      #Dumper($d);
    #return ( map { '%' . $_ } @err );
  }

  my (@tex, @after);
  my $w2h;
  {
    my $iinfo = image_info($img_file);
    my ($w, $h) = map { $iinfo->{$_} } qw( width height );
    $w2h = $h ? ($w*1.0)/$h : '';
    push @tex, '% w2h = ' . $w2h;
  }

  my $caption = $d->{caption};
  if ($caption){
    Plg::Projs::Tex::texify(\$caption);
    $caption = escape_latex($caption);
  }

  # current graphic width
  my $wd = $d->{width} || $rw->{width_tex};

###cell_width
  if($tab){
    my $cell = $tab->{cell} || {};

    $wd = $cell->{width} || $tab->{width}*$w2h;
    my $locals = $self->{locals} || {};

    $wd = ( $locals->{force} ? $locals->{width} : 0 ) || $d->{width} || $wd;

  }else{
    unless ($wd) {
      my $mlc = $self->{multicols};
      if ($mlc) {
        my %mlc_w = (
          2 => 0.45,
          3 => 0.3,
          4 => 0.23,
          5 => 0.18,
        );
        my $cols = $mlc->{cols};
        $wd = $mlc_w{$cols} || 1.0/$cols;
      }
    }
  }

  unless ($d->{width_by}) {
    if ($d->{type} eq 'igc') {
      $d->{width_by} = $self->{width_by_igc};
    }
  }

  $wd = $wd/$d->{width_resize} if $d->{width_resize};
  $wd = $wd*$d->{width_by} if $d->{width_by};

  if ($tab) {
    $self->tab_cell_update({ wd => $wd }) if $wd;
  }

  push @tex,
    $tab ? sprintf('%%tab row: %s, col: %s ', @{$tab}{qw(i_row i_col)}) : (),
    $wd ? sprintf('\setlength{\cellWidth}{%s}',$self->_len2tex($wd)) : ();

  my @o;
  push @o, 
    q{ keepaspectratio },
    $wd ? q{ width=\cellWidth } : (),
    ;

  if (my $rotate = $d->{rotate}) {
    #my $dict_rotate = opts_dict($rotate);
    push @o, $rotate;
  }

  my $o = join(",",@o);

  my (@ig, $ig_cmd); 
  $ig_cmd = sprintf(q|  \includegraphics[%s]{%s} |, $o, $img_path );
  if ($mkr->{box}) {
    # body...
  }

  push @ig, 
    $ig_cmd;

  my $repeat = $d->{repeat};
  if ($repeat && $repeat =~ /^(\d+)$/) {
    my $times = $1;
    $times--;

    if ($times > 0) {
       push @ig, $ig_cmd for ( 1 .. $times );
    }
  }

  my $wrap = $d->{'@wrap'} || $d->{'wrap'} || '';
  my $parpic = ( ref $wrap eq 'ARRAY' && grep { /parpic/ } @$wrap )
        || ( $wrap =~ /parpic/ );

  my ($width_parbox, $parbox);
  my ($width_minipage, $minipage);

  $minipage = $self->_val_('tab cell minipage') || $d->{minipage} || '';
  $parbox   = $self->_val_('tab parbox') || $d->{parbox} || '';

  $parbox   = $wd if $parbox eq 'auto';
  $minipage = $wd if $minipage eq 'auto';

  my $comments = $d->{comments};
  if ($comments) {
    my $resized = $minipage || $parbox;
    foreach my $x (@$comments) {
       $x =~ s/^\s*$/\\newline/g if $parpic;
       #$x = $self->_expand_igg($x,{ resized => $resized });
       $x = $self->_expand_igg($x,{});
    }
    unless ($minipage || $parbox) {
        $minipage ||= 1;
        $width_minipage ||= '\cellWidth';
    }
    push @$comments,'\bigskip' if $minipage || $parbox;
  }

  $width_parbox ||= $parbox || '\cellWidth';
  $width_minipage ||= $minipage || '\cellWidth';

  push @tex, $self->_wrapped($wrap,'start');

  if ($caption) {
    unless ($minipage) {
      $width_parbox ||= $parbox || '\cellWidth';
      $parbox = 1 unless $minipage;
    }
  }

  my $captionsetup = $d->{captionsetup} || ( $tab ? $tab->{captionsetup} : '' ) || $globals->{captionsetup};

  if ($globals->{mlc}) {
     push @tex,
             '',
             @ig,
             '',
             $caption ? $caption : (),
             $comments ? (@$comments) : (),
     ;

     return @tex;
  }

  unless($tab){
     push @tex,
        $self->_fig_start($d), # () if not figure
          $minipage ? sprintf('\begin{minipage}{%s}%%', $self->_len2tex($width_minipage) ) : (),
            $parbox ? sprintf('\parbox{%s}{%%', $self->_len2tex($width_parbox) ) : (),
              @ig,
              $captionsetup ? sprintf('\captionsetup{%s}%%', $captionsetup ) : (),
              $caption ? $self->_tex_caption($d, $caption) : (),
              $comments ? (@$comments) : (),
              $d->{cap} ? sprintf('\begin{center}\figCapA{%s}\end{center}',$d->{cap}) : (),
            $parbox ? '}%' : (),
          $minipage ? '\end{minipage}%' : (),
        $self->_fig_end($d),   # () if not figure
        @after,
        ;
  }else{

    push @tex, $minipage ? sprintf('\begin{minipage}{%s}%%', $self->_len2tex($width_minipage) ) : ();
    push @tex,   $parbox ? sprintf('\parbox[t]{%s}{%%', $self->_len2tex($width_parbox) ) : ();
    #push @tex,     $caption ? ( sprintf(q|%% %s|, $caption )) : ();
    push @tex,      @ig;
    push @tex,      $captionsetup ? sprintf('\captionsetup{%s}%%', $captionsetup ) : ();
    push @tex,      $caption ? $self->_tex_caption($d, $caption) : ();
    push @tex,      $comments ? (@$comments) : ();
    push @tex,      $d->{cap} ? sprintf('\begin{center}\figCapA{%s}\end{center}',$d->{cap}) : ();
    push @tex,   $parbox ? '}%' : ();
    push @tex, $minipage ? '\end{minipage}%' : ();
    push @tex, @after;

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

  unless ($mkr->{box}) {
      unshift @{$self->{nlines}},
         ' ',
         sprintf(q{\def\imgroot{%s}}, $mkr->{img_root_unix} ),
         ' '
         ;
  }

  my $nlines = $self->{nlines};
  write_file($file,join("\n",@$nlines) . "\n");

  return $self;
}

sub _macro_fbicon {
  my ($self, $arg, $opts_s) = @_;
}

sub _macro_igg {
  my ($self, $igname, $opts_s, $ref) = @_;

  $ref ||= {};

  my @ignames = 
     grep { !/^(\d+)$/ }
     split ' ' => $igname;

  if(@ignames > 1){
     my ($tex, @tex);
     for(@ignames){
        push @tex, $self->_macro_igg($_, $opts_s, $ref);
     }
     $tex = join("\n",@tex);
     return $tex;
  }

  $igname = trim($igname);

  my $d = {
     name => $igname, 
     type => 'ig' 
  };

  hash_update( $d, $self->_opts_dict($opts_s) );
  my $resized = $ref->{resized};
  $d->{width_resize} = $resized if $resized;

  my ($tex, @tex);
  push @tex, $self->_d2tex($d);
  $tex = join("\n",@tex);

  return $tex;
}

sub loop {
  my ($self) = @_;

  my @jlines = @{$self->{jlines} || []};

  $self->{lnum} = 0;
  foreach(@jlines) {
    $self->{lnum}++; chomp;

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
       if ($self->{is_cmt}) {
           $self->lpush_d;
           $self->{$_} = undef for(qw( is_cmt locals globals_block ));
       }else{
           $self->ldo_no_cmt;
       }
       #push @{$self->{nlines}},'}';
       next; 
    };

    if ($self->{is_cmt} && $self->{is_key}) {
       my $key = $self->{is_key};

###m_@ctl_end
       m/^\s*\@$key%end\s*$/g && do { $self->ctl_end($key); next; };
       push @{$self->{key_val}},trim($_); next;
    }

###m_comment
    m/^\s*%/ && do { push @{$self->{nlines}},$_; next; };

###m_caption_begin
    m/^\s*\@caption_begin\b(.*)/g && do { $self->match_caption_begin($1); next; };
    m/^\s*\@caption_end\b(.*)/g && do { $self->match_caption_end($1); next; };

    if ($self->{is_caption}) {
        my $obj = $self->{d} || $self->{tab};
        next unless $obj;

        $_ = $self->_expand_kv('caption', $_);

        $obj->{caption} ||= '';
        $obj->{caption} .= ( $obj->{caption} ? ' ' : '' ) . trim($_);
    }

###m_caption_setup
    #m/^\s*\@caption_setup\b(.*)/g && do { $self->match_caption_setup($1); next; };
    #

###m_block_end
    if ($self->{is_cmt}) {
       m/^\s*(\w+)/ && do {
          my $k = $1;

          $DB::single = 1 if $k eq 'dbg';

          my @block_end = qw( 
            tex tex_start 
            tab_begin tab_end
            pic doc
            ig igc
            globals locals
          );
          if ( grep { /^$k$/ } @block_end ) {
             $self->lpush_d;
          }
          if ( grep { /^$k$/ } qw( pic doc ig igc tex tex_start ) ) {
             $self->lpush_tab_start;
          }
       };
    }else{
       $self->ldo_no_cmt;
       next;
    }

    m/^\s*yaml_end\s*$/g && do { $self->match_yaml_end; next; };
    m/^\s*yaml_begin\s*$/g && do { $self->match_yaml_begin; next; };

    if ($self->{is_yaml}) {
       push @{$self->{yaml}}, $_;
       next;
    }

###m_tex
    m/^\s*tex\s+(.*)$/g && do {
        my $tex = trim($1);
        my $tab = $self->{tab};

        if ($tab) {
          push @{$tab->{store}}, $tex;
        }else{
          push @{$self->{nlines}}, $tex;
        }
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

    m/^\s*author_(end|begin|id)\s*$/g && do { next; };
###m_author
    m/^\s*author_end\s*$/g && do { $self->match_author_end; next; };
    m/^\s*author_begin\s*$/g && do { $self->match_author_begin; next; };
    m/^\s*author_id\s*(.*)\s*$/g && do { $self->match_author_id($1); next; };
   
###m_tab
    m/^\s*tab_begin\b(.*)/g && do { $self->match_tab_begin($1); next; };
    m/^\s*tab_end\s*$/g && do { $self->match_tab_end; next; };

###m_pic@
    m/^\s*(pic|doc|ig|igc)@(.*)$/g && do {
       my $v;
       $v = trim($2) if $2;

       next unless $v;

       my $opts = $self->_opts_dict($v);   
       next unless $opts;

       $self->{d} = { type => $1 };

       hash_update( $self->{d}, $opts);

       next;
    };

###m_globals
    m/^\s*globals\s*$/g && do {
       $self->{globals} ||= {};
       $self->{globals_block} = 1;
       next;
    };

###m_globals_end
    m/^\s*endglobals\s*$/g && do {
       $self->{globals_block} = undef;
       next;
    };

###m_pic
    m/^\s*(pic|doc|ig|igc)(?:\s+(.*)|\s*)$/g && do {
       my $v;
       $v = trim($2) if $2;

       $self->{d} = { type => $1 };

       $self->{d}->{url} = $v if $v;

       next;
    };

###m_import
    m/^\s*(import)\s*$/g && do {
       $self->{d} = { type => $1 };

       next;
    };

###m_@ctl_start
    m/^\s*(?:@|)(?<key>\w+)%start\s*$/g && do {
       my $key  = $+{'key'};
       my $ctl  = $+{'ctl'};

       my ($d, $tab) = @{$self}{qw(d tab)};

       $self->{is_key} = $key;
       $self->{key_val} ||= [];

       next;
    };

###m_@keyword
    m/^\s*(?:@|)(?<key>\w+)(?:|\[(?<type>\w+)\])\s+(?<value>.*)$/g && do {
      my $k    = $+{'key'};
      my $v    = trim($+{'value'});
      my $type = $+{'type'} || 'string';

      $v = $self->_expand_kv($k, $v);

      if ($type eq 'dict'){
         $v = $self->_opts_dict($v);
      }

      my ($d, $tab, $locals, $globals) = @{$self}{qw( d tab locals globals )};

      if($d){
         dict_update_kv($d, $k => $v);

      }elsif($tab){
         dict_update_kv($tab, $k => $v);

      }elsif($globals && $self->{globals_block}){
         $self->globals_update($k => $v);

      # variables within ifcmt ... fi block
      }elsif($locals){
         dict_update_kv($locals, $k => $v);
      }

      next;
    };

   }

  return $self;

}

1;
 

