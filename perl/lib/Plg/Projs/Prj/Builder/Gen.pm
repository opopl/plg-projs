
package Plg::Projs::Prj::Builder::Gen;

use utf8;

binmode STDOUT,':encoding(utf8)';

use strict;
use warnings;

use String::Util qw(trim);

use Data::Dumper qw(Dumper);
use Base::Data qw(
    d_str_split_sn
    d_path
);

=head3 _gen_sec

=head4 Call tree

	_join_lines  Plg::Projs::Build::Maker::Join

=cut

sub _gen_sec {
    my ($bld, $sec) = @_;

    my $on = $bld->_val_list_ref_('sii generate on');
    return () unless grep { /^$sec$/ } @$on;

    my @lines = $bld->_sct_lines($sec);
    return @lines;
}

1;

