
package Plg::Projs::Scripts::MkInd;

use strict;
use warnings;

use Plg::Projs::Build::PdfLatex;

use FindBin qw($Bin $Script);
use Cwd;
use Data::Dumper qw(Dumper);

use File::stat;
use File::Path qw(rmtree);

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
            LOCATION:
                $0
            USAGE:
                $Script PROJ
        } . "\n";
        exit 1;
    }

    my $proj = shift @ARGV;
    my $root = getcwd();

    my $blx = Plg::Projs::Build::PdfLatex->new( 
        skip_get_opt => 1,
        proj         => $proj,
        root         => $root,
    );

    my $h = {
        proj => $proj,
        root => $root,
        blx  => $blx,
    };
        
    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

    return $self;
}

sub run {
	my ($self) = @_;

	my $root = $self->{root};

	my $blx = $self->{blx};

    my @texindy = $blx->_cmds_texindy({ dir => $root });
	print Dumper(\@texindy) . "\n";

    return $self;
}

1;
 

