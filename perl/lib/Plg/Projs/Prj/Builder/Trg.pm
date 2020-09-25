

package Plg::Projs::Prj::Builder::Trg;

use strict;
use warnings;

use Base::Arg qw(hash_inject);

sub inj_targets {
    my ($self) = @_;

    foreach my $trg ($self->trg_list) {
        my $sub = '_trg_inj_' . $trg;
        if ($self->can($sub)) {
            $self->$sub;
        }
    }
}

sub trg_list {
    my ($self) = @_;

    @{ $self->{trg_list} || [] };
}

sub trg_inject {
    my ($self, $trg, $hash ) = @_;

    hash_inject($self, { targets => { $trg => $hash }} );

    return $self;

}

sub _trg_inj_usual {
    my ($self) = @_;

    my $h = {
        tex_exe => 'pdflatex',
        insert => { 
            hyperlinks => 1,
            titletoc   => 1,
        },
        opts_maker => {
            load_dat => {
                ii_include => 1,
            },
            sections => {
                include => [],
            }
        }
    };

    $self->trg_inject('usual' => $h);

    return $self;
}

1;
 

