
package Plg::Projs::Scripts::IndInsBmk;

use strict;
use warnings;

use base qw(
	Plg::Projs::Build::PdfLatex::IndFile
);

use FindBin qw($Bin $Script);

sub new
{
	my ($class, %opts) = @_;
	my $self = bless (\%opts, ref ($class) || $class);

	$self->init if $self->can('init');

	return $self;
}


sub init {
	my $self = shift;

	unless (@ARGV) {
		print qq{
			USAGE:
				$Script INDFILE LEVEL
		} . "\n";
		exit 1;
	}

	my $h = {
		ind_file  => shift @ARGV,
		ind_level => shift @ARGV,
	};
		
	my @k = keys %$h;

	for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

	return $self;
}

1;
 

