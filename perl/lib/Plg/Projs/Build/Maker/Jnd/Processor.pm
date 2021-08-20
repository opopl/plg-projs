
package Plg::Projs::Build::Maker::Jnd::Processor;

use strict;
use warnings;

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Base::Arg qw( hash_inject );
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
	
	my $h = {};
		
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

1;
 

