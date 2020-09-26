

package Plg::Projs::Prj::Builder::Trg;

use strict;
use warnings;

use Base::Arg qw(hash_inject);

sub inj_targets {
    my ($self) = @_;

    foreach my $trg ($self->_trg_list) {
        my $sub = 'trg_inj_' . $trg;
        if ($self->can($sub)) {
            $self->$sub;
        }
    }
    return $self;
}

sub _trg_list {
    my ($self) = @_;

    @{ $self->{trg_list} || [] };
}

sub trg_inject {
    my ($self, $trg, $hash ) = @_;

    hash_inject($self, { targets => { $trg => $hash }} );

    return $self;

}

sub trg_load_xml {
	my ($self) = @_;

	return $self;
}

sub _trg_opts_maker {
    my ($self, $target, @args) = @_;

    $target //= $self->{target};

    my $om = $self->_val_('targets',$target,'opts_maker',@args);

    return $om;

}

sub trg_inj_usual {
    my ($self) = @_;

    my $om = {
		tex_exe => 'xelatex',
        skip_get_opt => 1,
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
            include => $self->_secs_include,
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
                titletoc   => $self->_insert_titletoc,
                hyperlinks => $self->_insert_hyperlinks,
            },
            generate => {
            },
            append => {
                each => sub { },
                only => {
                    defs => sub {
                        [ $self->_def_sechyperlinks ];
                    },
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
 

