
package Plg::Projs::Prj::Data;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Dat::Utils qw(readhash);

###see_also projs#data#dict

sub _data_dict {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $file = $self->_data_dict_file($ref);
    return {} unless -e $file;

    my $dict = readhash($file);

    return $dict;
}

###see_also projs#data#dict_file

sub _data_dict_file {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $root = $self->{root};

    my $id   = $ref->{id} || '';
    my $proj = $ref->{proj} || '';

    my @a = ( $root, qw( data dict ));
    if ($proj) {
        push @a,$proj;
    }

    my $file = catfile(@a,printf(q{%s.i.dat}, $id) );
    return $file;
}

1;
 

