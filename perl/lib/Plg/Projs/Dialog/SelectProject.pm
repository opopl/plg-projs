
package Plg::Projs::Dialog::SelectProject;

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Tk;

use FindBin qw($Bin $Script);

my $plg_dir = "$Bin/../../";

use lib "$plg_dir/base/perl/lib";
use lib "$plg_dir/projs/perl/lib";

use base qw(Plg::Base::Dialog);

sub init {
	my $self = shift;

	$self->SUPER::init();

	my $h = { };
		
	my @k = keys %$h;

	for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

	return $self;
}

1;
 

