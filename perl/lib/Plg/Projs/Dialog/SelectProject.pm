
package Plg::Projs::Dialog::SelectProject;

=head1 NAME

Plg::Projs::Dialog::SelectProject - Tk dialog for selecting a project

=cut

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Tk;
use Tk::widgets;
use Tk::ListBox;

use FindBin qw( $Bin $Script );

use lib "$Bin/../../base/perl/lib";
use lib "$Bin/../perl/lib";

use base qw( Plg::Base::Dialog );

=head2 tk_proc

Will be called by C<tk_run()> method defined in L<Plg::Base::Dialog>

=cut

sub tk_proc { 
	my ($self, $mw) = @_;

	my @projs = @{$self->{data}->{projs} || []};

	require Tk;
	require Tk::widgets;
	require Tk::ListBox;

	my $lb = $mw->ListBox->pack();
	$lb->insert('end', @projs);

	return $self;
}

sub init {
	my $self = shift;

	$self->SUPER::init();

	my $h = { };
		
	my @k = keys %$h;

	for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

	return $self;
}

1;
 

