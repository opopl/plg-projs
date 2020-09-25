
package Plg::Projs::Scripts::IndInsBmk;

use strict;
use warnings;

use base qw(
    Plg::Projs::Build::Maker::IndFile
);

use FindBin qw($Bin $Script);
use Base::Arg qw(hash_inject);

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
                perl $Script INDFILE LEVEL
        } . "\n";
        exit 1;
    }

    my $h = {
        ind_file  => shift @ARGV,
        ind_level => shift @ARGV,
    };

	hash_inject($self, $h);

    return $self;
}

1;
 

