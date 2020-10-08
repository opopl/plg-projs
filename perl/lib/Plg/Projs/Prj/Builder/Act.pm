
package Plg::Projs::Prj::Builder::Act;

use utf8;

binmode STDOUT,':encoding(utf8)';

use strict;
use warnings;

sub act_dump_bld {
    my ($bld) = @_;

    my $data = $bld->_opt_argv_('data','');

    $bld->dump_bld($data);
    exit 1;
}

sub act_show_trg {
    my ($bld) = @_;

    foreach my $trg ($bld->_trg_list) {
        print $trg . "\n";
    }
    exit 1;
}

1;
 

