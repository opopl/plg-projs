
package Plg::Projs::Prj::Builder::Var;

use strict;
use warnings;

sub _bld_var {
    my ($bld, $var) = @_;

    my $vars = $bld->_val_('vars') // '';

    my $val;
    if (ref $vars eq 'ARRAY') {
        my %values;
        foreach my $v (@$vars) {
            if (ref $v eq 'HASH') {
                my $name = $v->{name} // '';
                my $value = $v->{value} // $v->{'#text'} // '';
                next unless $name;
                $values{$name} = $value;
            }
        }
        $val = $values{$var} // '';
    }
    elsif (ref $vars eq 'HASH') {
        $val = $vars->{$var} // '';
    }

    return $val;
}

1;
 

