
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
    my ($bld, $path) = @_;

	my $h = $bld->_val_($path);
	my $data = ref $h eq 'HASH' ? { map { $_ => $h->{$_} } keys %$h } : $h;
    print Dumper($data) . "\n";
    return $bld;
}


1;
 

