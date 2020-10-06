
package Plg::Projs::Prj::Builder::Sct;

use strict;
use warnings;

sub _sct_data {
    my ($bld, $sec) = @_;

    my $scts = $bld->_val_('sii scts') || [];
    my @data = map { $_->{name} eq $sec ? $_ : () } @$scts;

    my %data;
    foreach my $x (@data) {
        while(my($k,$v) = each %$x){
            $data{$k} = $v;
        }
    }

    return {%data};
}

1;
 

