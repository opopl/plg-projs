

package Plg::Projs::Prj::Builder::Trg::core;

use utf8;
use strict;
use warnings;

sub trg_inj_core {
    my ($self) = @_;

    my $bld = $self;

    my $om = {
        sections => { 
            line_sub => sub {
                my ($line,$r_sec) = @_;
    
                my $sec = $r_sec->{sec};
    
                return $line;
            },
            insert => {
                titletoc   => sub { $bld->_insert_titletoc },
                hyperlinks => sub { $bld->_insert_hyperlinks },
            },
            append => {
                each => sub { },
                only => {
                    #defs => sub { [ $bld->_def_sechyperlinks ] },
                },
            },
        }
    };

    my $h = {
        tex_exe    => 'pdflatex',
        sii        => {},
        opts_maker => $om,
    };

    $self->trg_inject( 'core' => $h );

    return $self;
}

1;
 

