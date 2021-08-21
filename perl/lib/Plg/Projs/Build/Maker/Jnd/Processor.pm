
package Plg::Projs::Build::Maker::Jnd::Processor;

use strict;
use warnings;

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Base::Arg qw(
  hash_inject
  hash_update
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
       data => [],
       d => {},
       d_author => undef,
       img_width => undef,
       img_width_default => 0.7,
       keys => [qw(url caption tags name)],
       nlines => [],

       img      => undef,
       img_path => undef,
       url      => undef,
       caption  => undef,

       is_img => undef,
       is_tab => undef,
       is_cmt => undef,
       lnum => 0,

       ct => undef,

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

sub tab_defaults {
  my $self = shift;

  return unless $self->{tab};
  my $h = {
      cols       => 2,
      align      => 'c',
      env        => 'tabular',
      i_col      => 1,
      i_row      => 1,
      i_cap      => 1,
      col_type   => 'img',
      fig_env    => 'figure',
      row_caps   => {},
      cap_list   => [],
  };
  hash_inject($self->{tab}, $h);

  return $self;
}

sub _tab_col_type {
  my ($self, $type) = @_;
  return unless $self->{tab};

  $self->{tab}->{col_type} = $type if $type;
  
  return $self->_val_('tab col_type');
}

sub _tab_col_type_toggle {
  my ($self) = @_;

  while(1){
    my $ct = $self->_tab_col_type;

    ( $ct eq 'cap') && do { $self->_tab_col_type('img'); last; };
    ( $ct eq 'img') && do { $self->_tab_col_type('cap'); last; };

    last;
  }

  return $self->_tab_col_type;
}

sub _tab_num_cap {
  my ($self) = @_;
  my $tab = $self->{tab};
  return unless $tab;

  my $rc = $tab->{row_caps};
  return unless keys %$rc;

  my $i_col  = $tab->{i_col};
  my $rc_col = $rc->{$i_col} || {};
  my $i_cap  = $rc_col->{i_cap};

  return $i_cap;
}

sub _tab_start {
  my ($self) = @_;
  my $tab = $self->{tab};

  ($tab) ? sprintf(q| \begin{%s}{*{%s}{%s}} |,@{$tab}{qw(env cols align)}) : '';
}

sub _tex_caption_tab { 
  my ($self) = @_;
  my $tab = $self->{tab};
  return unless $tab;

  my $c = $tab->{caption} || '';
  return unless $c;

  my @caps = map { sprintf('\textbf{(%s)} %s', @{$_}{qw(i_cap caption)}) } @{$tab->{cap_list}};
  my $c_long = join(" ", $c, @caps );

  my @c; push @c, sprintf(q| \caption[%s]{%s} |, $c, $c_long );
  return @c;
}

# _width <=> $get_width
sub _width {
  my ($self) = @_;
  my $w = $self->_val_('d width') || $self->_val_('tab width') || $self->{img_width_default};

  return $w;
}

sub _width_tex {
  my ($self) = @_;

  my $w = $self->_width;
  for($w){
      /^(\d+(?:|\.\d+))$/ && do {
          $w = qq{$w\\textwidth};
      };
      last;
  }
  return $w;
}

sub push_d {
  my ($self) = @_;

  my $d = $self->{d};

  push @{$self->{data}}, { %$d } if keys %$d;

  return $self;
}

sub push_d_reset {
  my ($self) = @_;

  $self->push_d;
  $self->{d} = {};

  return $self;
}

sub _tex_caption {
  my ($self) = @_;

  $self->{caption} ? ( sprintf(q| \caption{%s} |, $self->{caption} ) ) : ();
}

sub set_null {
  my ($self) = @_;

  my $h = {
     fig     => [],
     d       => {},
     caption => '',
     tab     => undef,
  };

  hash_update($self,$h);

  return $self;
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
  (grep { /^$t$/ } qw(ig)) ? 1 : 0;

  return $self;
}

sub loop {
  my ($self) = @_;

  my $mkr = $self->{mkr};

  my @jlines = @{$self->{jlines} || []};

  foreach(@jlines) {
    $self->{lnum}++; chomp;

    $self->{line} = $_;

    m/^\s*%/ && $self->{is_cmt} && do { push @{$self->{nlines}},$_; next; };

###m_ii
    m/^\s*%%\s*\\ii\{(.*)\}\s*$/ && do {
       $self->{sec} = $1;
    };

###m_\ifcmt
    m/^\s*\\ifcmt/ && do { $self->{is_cmt} = 1; next; };
###m_\fi
    m/^\s*\\fi/ && do { 
       unless($self->{is_cmt}){
          push @{$self->{nlines}},$_; next;
       }

       if ($self->{is_img}) {
          $self->{is_img} = 0;
          $self->push_d_reset;
       }

       $self->{is_cmt} = 0 if $self->{is_cmt}; 

       next unless @{$self->{data}};

###if_tab_push_tab_start
       if ($self->{tab}) {
         $self->tab_defaults;

         $self->{tab}->{width} ||= ( $self->{img_width_default} / $self->{tab}->{cols} );
         push @{$self->{fig}}, $self->_fig_start, $self->_tab_start;
       }

       #print join(" ", $lnum,  scalar @data ) . "\n";

###while_@data
       while(1){
         $self->{ct}   = $self->_tab_col_type;

###if_ct_img
         if (@{$self->{data}} && (!$self->{ct} || ($self->{ct} eq 'img')) ){
            $self->{d} = shift @{$self->{data}} || {};
            $self->{img} = undef;
    
            my $w = {};
            for(qw( url name )){
               $w->{$_}  = $self->{d}->{$_} if $self->{d}->{$_};
            }
    
            my ($rows, $cols, $q, $p) = dbh_select({
                 dbh => $mkr->{dbh_img},
                 q   => q{ SELECT img, caption, url FROM imgs },
                 p   => [],
                 w   => $w,
            });

            unless (@$rows) {
                 my $url = $self->{url};
                 my $r = {    
                     msg => q{ No image found in Database! },
                     url => $url,
                 };
                 warn Dumper($r) . "\n";
                 push @{$self->{nlines}}, qq{%Image not found: $url };
                 next;
            }

            next unless @$rows;

            $self->{$_} = $self->{d}->{$_} for @{$self->{keys}};
    
            $self->{caption} = texify($self->{caption}) if $self->{caption};

###if_tab_push_row_caps
            if ($self->{tab}) {
               my $tab = $self->{tab};

               my $i_col = $tab->{i_col};
    
               if ($self->{caption}) {
                  $tab->{row_caps}->{$i_col} = { 
                      caption => $self->{caption},
                      i_cap   => $tab->{i_cap},
                  };
        
	              push @{$tab->{cap_list}},
	                 { 
	                     i_col   => $tab->{i_col},
	                     i_row   => $tab->{i_row},
	                     i_cap   => $tab->{i_cap},
	                     caption => $self->{caption},
	                 }
                     ;
                  $tab->{i_cap}++;
               }
            }

            $self->{img_width} = $self->_width;
    
            if (@$rows == 1) {
                my $rw = shift @$rows;
                $rows = [];

                $self->{$_} = $rw->{$_} for(qw(img));
        
                my $img_path = sprintf(q{\imgroot/%s},$self->{img});
        
                my $img_file = catfile($mkr->{img_root},$self->{img});
                unless (-e $img_file) {
                    my $r = {    
                        msg => q{Image file not found!},
                        img => $self->{img},
                        url => $self->{url},
                    };
                    warn Dumper($r) . "\n";
                    next;
                }
    
                push @{$self->{fig}},$self->_fig_start unless $self->{tab};

                my $o = sprintf(q{ width=%s\textwidth },$self->{img_width});
###push_includegraphics

                push @{$self->{fig}}, 
                    $self->{tab} ? (sprintf('%% row: %s, col: %s ', @{$self->{tab}}{qw(i_row i_col)})) : (),
                    #sprintf(q|%% %s|,$url),
                    sprintf(q|  \includegraphics[%s]{%s} |, $o, $self->{img_path} ),
                    $self->{caption} ? (sprintf(q|%% %s|,$self->{caption})) : (),
                    ;
            }

###end_if_ct_img
         }elsif($self->{ct} && ($self->{ct} eq 'cap')){
            #print join(" ",qq{$ct},@{$tab}{qw(i_col i_row)}) . "\n" if $ct;
            my $num_cap = $self->_tab_num_cap;
            push @{$self->{fig}}, sprintf('(%s)',$num_cap) if $num_cap;

	     }else{
            last;
         }
###end_if_ct_cap

###if_tab_col
         if ($self->{tab}) {
            my $tab = $self->{tab};
            my $ct = $self->{ct};

            $self->{caption} = undef;
            my ($s, %caps);

            %caps = %{$self->_val_('tab row_caps')};

            my $at_end = ( $self->_val_('tab i_col') == $self->_val_('tab cols') ) ? 1 : 0;
            if ($at_end) {

               $tab->{i_col} = 1;

               $tab->{i_row}++ if $ct eq 'img';
               $tab->{row_caps} = {} if $ct eq 'cap';

               unless(@{$self->{data}}){
                   last unless keys %caps;
               }

###call_tab_col_toggle
                            # if there are any captions, switch row type to 'cap'
               $ct = $self->_tab_col_type_toggle if keys %caps;

               $s = q{\\\\};
             }else{
               $s = q{&};
               $tab->{i_col}++;
             }

             push @{$self->{fig}}, $s;

         }elsif(keys %{$self->{d}}){
                        #print Dumper({ '$d' => $d }) . "\n";
###push_fig_end
             push @{$self->{fig}}, $self->_tex_caption, $self->_fig_end;

         }

         unless (@{$self->{data}}) {
             my $ct = $self->{ct};
             my $tab = $self->{tab};

             do { last; } unless $ct;
             do { last; } if ( $ct eq 'cap' ) && ($tab->{i_col} == $tab->{cols});
         }
                next;
       }
###end_loop_@data

       if($self->{tab}){
         push @{$self->{fig}}, 
            $self->_tab_end, $self->_tex_caption_tab,
            $self->_fig_end;
       }

       push @{$self->{nlines}}, @{$self->{fig}};

       $self->_set_null;

       next LINES; 
   };
###end_m_\fi

   unless($self->{is_cmt}){ push @{$self->{nlines}}, $_; next; }

###m_author_begin
   m/^\s*author_begin\b(.*)$/g && do { 
      $self->{d_author} = {};
   };

###m_author_end
   m/^\s*author_end\b(.*)$/g && do { 
      my @author_ids = split("," => $self->_val_('d_author author_d') || '');
      next unless @author_ids;

      foreach my $author_id (@author_ids) {
         my $prj    = $mkr->{prj};
         my $author = $prj->_author_get({ author_id => $author_id });
    
         $author =~ s/\(/ \\textbraceleft /g;
         $author =~ s/\)/ \\textbraceright /g;
    
         push @{$self->{nlines}}, sprintf(q{\Pauthor{%s}}, $author) if $author;
    
         $self->{d_author} = undef;

      }
      next;
   };

   if ($self->{d_author}) {
      m/^\s*(\w+)\s+(\S+)\s*$/g && do { 
         $self->{d_author}->{$1} = $2;
         next;
      };
   }

###m_tab_begin
   m/^\s*tab_begin\b(.*)$/g && do { 
     $self->{is_tab} = 1; 
     my $opts_s = $1;
     next unless $opts_s;

     $self->{tab}={};

     my @tab_opts = grep { length } map { defined ? trim($_) : () } split("," => $opts_s);
     for(@tab_opts){
        my ($k, $v) = (/([^=]+)=([^=]+)/g);
        $self->{tab}->{$k} = $v;
     }
            #print Dumper($tab) . "\n";
     next; 
   };

###m_img_begin
   m/^\s*img_begin\b/g && do { $self->{is_img} = 1; next; };

###m_tab_end
   m/^\s*tab_end\b/g && do { 
      $self->{$_} = 0 for(qw(is_tab is_img));

      $self->push_d_reset;
      $self->{caption} = undef;
      next; 
   };

###m_img_end
   m/^\s*img_end\b/g && do { 
     $self->{is_img} = 0 if $self->{is_img}; 

     $self->push_d_reset;

     next; 
   };

   while(1){
###m_pic_doc_ig
     m/^\s*(pic|doc|ig)\s+(.*)$/g && do { 
        $self->push_d_reset;

        $self->{is_img} = 1;

        $self->{url} = $2;
        $self->{d} = { url => $self->{url} };

        my $k = $1;
        $self->{d}->{type} = $k;
        last; 
     };

###if_is_img
     if ($self->{is_img}) {
###m_url
       m/^\s*url\s+(.*)$/g && do { 
         $self->push_d_reset;

         $self->{d} = { url => $1 };
         $self->{url} = $1;
         last;
       };

###m_other
       m/^\s*(\w+)\s+(.*)$/g && do { 
         my $k = $1;
         #next unless grep { /^$k$/ } qw( caption name tags );

         $self->{d}->{$1} = $2; 
       };

       last;
     }

     last;
   }

###m_other_tab
   m/^\s*(\w+)\s+(.*)$/g && do { 
     $self->{tab}->{$1} = $2 if $self->{tab};
     next;
   };

  }

  return $self;

}

1;
 

