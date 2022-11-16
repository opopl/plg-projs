
package projs::_rootid_::_proj_::bld;

use strict;
use warnings;

use FindBin qw($Bin $Script);
use Data::Dumper qw(Dumper);

use File::Spec::Functions qw(catfile);
use Getopt::Long qw(GetOptions);

use base qw(
    Plg::Projs::Prj::Builder
);

use Base::Arg qw( hash_inject );

sub init {
    my ($bld) = @_;
    
    my $h = {
        trg_list => [qw(usual)],
        tex_exe  => 'pdflatex',
        callbacks => {
          maker => {
          }
        },
        custom => {
           maps_act => {
           }
        },
    };

    hash_inject($bld, $h);

    $bld->SUPER::init();

    return $bld;
}

1;

