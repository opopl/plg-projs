
package Plg::Projs::Prj::Builder::Gen;

use utf8;

use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

sub _gen_preamble {
    my ($bld) = @_;

	my $on = $bld->_val_list_ref_('sii generate on');
	my $sec = 'preamble';

	return () unless grep { /^$sec$/ } @$on;
    my @lines;

    return @lines;
}

sub _gen_preamble_packages {
    my ($bld) = @_;

	my $on = $bld->_val_list_ref_('sii generate on');
	my $sec = 'preamble.packages';

	return [] unless grep { /^$sec$/ } @$on;

	my $packs = $bld->_val_list_ref_('sii generate on');

    my @lines;

    return @lines;
}

1;

