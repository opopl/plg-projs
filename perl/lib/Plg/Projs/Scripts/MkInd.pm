
package Plg::Projs::Scripts::MkInd;

use strict;
use warnings;

use Plg::Projs::Build::Maker;

use FindBin qw($Bin $Script);
use Cwd;
use Data::Dumper qw(Dumper);

use File::stat;
use File::Path qw(rmtree);

use Base::Arg qw( hash_update );

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub init {
    my $self = shift;

    my $pack = __PACKAGE__;
    unless (@ARGV) {
        print qq{
            PACKAGE:
                $pack
            LOCATION:
                $0
            USAGE:
                perl $Script PROJ
        } . "\n";
        exit 1;
    }

    my $proj = shift @ARGV;
    my $root = getcwd();

    my $blx = Plg::Projs::Build::Maker->new( 
        skip_get_opt => 1,
        proj         => $proj,
        root         => $root,
    );

    my $h = {
        proj => $proj,
        root => $root,
        blx  => $blx,
    };

    hash_update($self, $h, { keep_already_defined => 1 });
        

    return $self;
}

sub run {
    my ($self) = @_;

    my $root = $self->{root};

    my $blx = $self->{blx};

    my @texindy = $blx->_cmds_texindy({ dir => $root });
    foreach my $cmd (@texindy) {
        system("$cmd");
    }

    return $self;
}

1;
 

