
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

sub _bld_var_set {
    my ($bld, $var, $value) = @_;

    my $vars = $bld->_val_('vars') // {};

    if (ref $vars eq 'ARRAY') {
       push @$vars, {
           name  => $var,
           value => $value,
       };

    }elsif (ref $vars eq 'HASH') {
       $vars->{$var} = $value;
    }

    $bld->{vars} //= $vars;
}

1;
 

