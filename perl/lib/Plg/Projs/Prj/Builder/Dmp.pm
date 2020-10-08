
package Plg::Projs::Prj::Builder::Dmp;

use utf8;

binmode STDOUT,':encoding(utf8)';

use strict;
use warnings;

use Data::Dumper qw(Dumper);

sub dump_trg {
    my ($bld, $target) = @_;
    $target //= $bld->{target};

    my $ht = $bld->_val_('targets',$target) || {};
    print Dumper($ht) . "\n";
    return $bld;
}

sub dump_bld {
    my ($bld) = @_;

    print Dumper({ map { $_ => $bld->{$_} } keys %$bld }) . "\n";
    return $bld;
}


1;
 

