
package projs::_rootid_::_proj_::bld;

use strict;
use warnings;

use FindBin qw($Bin $Script);
use Data::Dumper qw(Dumper);

use File::Spec::Functions qw(catfile);
use Getopt::Long qw(GetOptions);

use Base::Arg qw(
	hash_update
);

use base qw(
	Plg::Projs::Prj::Builder
);

1;

