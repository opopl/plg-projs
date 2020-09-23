
package Plg::Projs::Build::Maker::Bat;

use strict;
use warnings;

sub _bat_ext {
    my ($self) = @_;

    my $ext = $^O eq 'MSWin32' ? 'bat' : 'sh';

    return $ext;
}

sub _bat_file {
    my ($self, $head) = @_;

    my $ext  = $self->_bat_ext;
    my $file = sprintf(q{%s.%s},$head,$ext);

    return $file;
}


1;
 

