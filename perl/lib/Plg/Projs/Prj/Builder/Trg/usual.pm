
package Plg::Projs::Prj::Builder::Trg::usual;

use utf8;
use strict;
use warnings;

sub trg_inj_usual {
    my ($self) = @_;

    my $bld = $self;

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
                titletoc   => sub { $bld->_insert_titletoc },
                hyperlinks => sub { $bld->_insert_hyperlinks },
            },
            generate => {
                'preamble.packages' => sub { $bld->_gen_preamble_packages },
                'preamble.packages.xelatex'  => sub {},
                'preamble.packages.pdflatex' => sub {},
            },
            append => {
                each => sub { },
                only => {
                    defs => sub { [ $bld->_def_sechyperlinks ] },
                },
            },
        }
    };

    my $h = {
        tex_exe => 'pdflatex',
        sii => {
            insert => {
               hyperlinks => 1,
               titletoc   => 1,
            },
            preamble => {
                packages  => [qw()],
                pack_opts => {},
            },
            generate => {
                on => [qw(
                   preamble.packages
                   preamble.packages.xelatex
                   preamble.packages.pdflatex
                )]
            },
        },
        opts_maker => $om,
    };

    $self->trg_inject( 'usual' => $h );

    return $self;
}

1;
 

