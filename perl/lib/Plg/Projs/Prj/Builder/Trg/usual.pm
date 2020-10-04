
package Plg::Projs::Prj::Builder::Trg::usual;

use strict;
use warnings;

sub trg_inj_usual {
    my ($self) = @_;

    my $om = {
        skip => {
            get_opt => 1,
        },
        join_lines   => {
            include_below => [qw(section)]
        },
        # _ii_include
        # _ii_exclude
        load_dat => {
            ii_include => 1,
            ii_exclude => 1,
        },
        sections => { 
            include_with_children => [qw(
                preamble
            )],
            line_sub => sub {
                my ($line,$r_sec) = @_;
    
                my $sec = $r_sec->{sec};
    
                return $line;
            },
            ins_order => [qw( hyperlinks titletoc )],
            insert => {
                titletoc   => sub { $self->_insert_titletoc },
                hyperlinks => sub { $self->_insert_hyperlinks },
            },
            generate => {
            },
            append => {
                each => sub { },
                only => {
                    defs => sub { [ $self->_def_sechyperlinks ] },
                },
            },
        }
    };

    my $h = {
        tex_exe => 'pdflatex',
        insert => {
           hyperlinks => 1,
           titletoc   => 1,
        },
        opts_maker => $om,
    };

    $self->trg_inject( 'usual' => $h );

    return $self;
}

1;
 

