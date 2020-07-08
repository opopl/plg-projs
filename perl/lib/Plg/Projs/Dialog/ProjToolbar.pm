
package Plg::Projs::Dialog::ProjToolbar;

=head1 NAME

Plg::Projs::Dialog::ProjToolbar - 

=cut

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Tk;
use Tk::widgets;

use FindBin qw( $Bin $Script );

use lib "$Bin/../../base/perl/lib";
use lib "$Bin/../perl/lib";

use base qw( Plg::Base::Dialog );

#https://www.perlmonks.org/?node_id=1185809
sub Tk::Separator
{
    my ($self, %rest ) = @_;
    my $direction = delete $rest{'-orient'} // 'horizontal';
    $self->Frame( %{ {%rest, -bg => 'black',
        $direction eq 'vertical' ? '-width' : '-height' => 2 } } );
}

=head2 tk_proc

Will be called by C<tk_run()> method defined in L<Plg::Base::Dialog>

=cut

sub tk_proc { 
    my ($self, $mw) = @_;

    $self->{mw} = $mw;

    my $proj       = $self->{data}->{proj} || '';
    my $servername = $self->{data}->{vim}->{servername} || '';

    $mw->title($proj);
    $mw->geometry("400x200+0+0"); 

    $self
        ->tk_frame_build
        ->tk_sep_hz
        ->tk_frame_view
        ->tk_sep_hz
        ->tk_frame_secs
        ;

    return $self;
}

sub tk_sep_hz {
    my ($self) = @_;

    my $mw = $self->{mw};

    $mw->Tk::Separator( 
        -orient => 'horizontal')
    ->pack( 
        -side => 'top', 
        -fill => 'x' 
    );

    return $self;
}

sub tk_frame_secs { 
    my ($self) = @_;

    my $mw = $self->{mw};

    my $fr_secs = $mw->Frame();

    $mw->Label( 
        -text => 'Sections', 
        -height => 2,
    )->pack;
        
    $fr_secs->pack(-side => 'top', -fill => 'x');

    $mw->Frame( 
        -height => 2, 
        -bg => 'black',
    )->pack( 
        -side => 'top', 
        -fill => 'x' );

    my $secs = [qw(
        _main_
        body 
        preamble 
        tabcont
        cfg
    )];

    foreach my $sec (@$secs) {
        my $expr = sprintf("projs#vim_server#sec_open('%s')",$sec);
        $fr_secs->Button(
            -text    => $sec,
            -command => $self->_vim_server_sub({
                'expr'  => $expr
            })
        )->pack(-side => 'left');
    }

    return $self;
}

sub tk_frame_view { 
    my ($self) = @_;

    my $mw = $self->{mw};

    $mw->Label( 
        -text => 'View', 
        -height => 2,
    )->pack;

    my $fr_view = $mw->Frame()->pack(-side => 'top', -fill => 'x');

    $fr_view->Button(
        -text    => 'View HTML',
        -command => $self->_vim_server_sub({
            'expr'  => 'projs#vim_server#html_out_view()'
        })
    )->pack(-side => 'left');

    $fr_view->Button(
        -text    => 'View PDF',
        -command => $self->_vim_server_sub({
            'expr'  => 'projs#vim_server#pdf_out_view()'
        })
    )->pack(-side => 'left');

    return $self;
}

sub tk_frame_build { 
    my ($self) = @_;

    my $mw = $self->{mw};

    $mw->Label( 
        -text => 'Build', 
        -height => 2,
    )->pack;

    my $fr_build = $mw->Frame()->pack(-side => 'top', -fill => 'x');

    $fr_build->Button(
        -text    => 'Build PDF',
        -command => $self->_vim_server_sub({
            'expr'  => 'projs#vim_server#async_build()'
        })
    )->pack(-side => 'left');

    $fr_build->Button(
        -text    => 'Build HTML',
        -command => $self->_vim_server_sub({
            'expr'  => 'projs#vim_server#async_build_htlatex()'
        })
    )->pack(-side => 'left');

    $fr_build->Button(
        -text    => 'Cleanup',
        -command => $self->_vim_server_sub({
            'expr'  => 'projs#vim_server#build_cleanup()'
        })
    )->pack(-side => 'left');

    return $self;
}

sub _vim_servername {
    my ($self) = @_;

    my $servername = $self->{data}->{vim}->{servername} || '';
    return $servername;
}

sub _vim_server_sub {
    my ($self, $ref) = @_;

    $ref ||= {};
    my $expr = $ref->{expr} || '';

    return sub { 
        my $cmd = $self->_vim_server_cmd({ 'expr'  => $expr });
        system("$cmd");
    };
}

sub _vim_server_cmd {
    my ($self,$ref) = @_;

    $ref ||= {};
    my $expr = $ref->{expr} || '';

    my $args = [    
        'gvim',
        '--servername ',$self->_vim_servername,
        '--remote-expr',$expr
    ];

    my $cmd = join(" " => @$args);
    return $cmd;
}

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $h = { };
    hash_update($self, $h, { keep_already_defined => 1 });

    return $self;
}

1;
 

