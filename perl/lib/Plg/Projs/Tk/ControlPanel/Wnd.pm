
package Plg::Projs::Tk::ControlPanel::Wnd;

use strict;
use warnings;

###btns
#
sub wnd_fill_projects_buttons {
    my ($self, $wnd) = @_;

    my $prj = $self->{prj};

    my @btns;
    my %p = ( -side => 'top', -fill => 'x' );

    my $cols = 5;
    my $j = 0;

    my ($nrow, $ncol);

    foreach my $proj ($prj->_projects) {

        $ncol = $j % $cols;
        $nrow = int $j/$cols;

        my $fr = $wnd->Frame( 
            -height      => 2,
            -bg          => 'black',
            -borderwidth => 3,
        );

        $fr->grid(
            -column => $ncol,
            -row    => $nrow
        );

        my $expr = sprintf(q{projs#vim_server#view_project('%s')},$proj);
        my $btn = $fr->Button(
            -text => $proj,
            -width  => 20,
            -height => 1,
            -command => $self->_vim_server_sub({
                'expr'  => $expr
            })
        ); 
        push @btns, $btn;

        $btn->pack(
            -side   => 'left',
            -fill   => 'x',
            -expand => 1,
        );

        $j++;
    }

    return $self;
}

###entry
sub wnd_fill_projects_entry {
    my ($self, $wnd) = @_;

    my $prj = $self->{prj};
    my $mw  = $self->{mw};

    my @projects = $prj->_projects;

#    my $fr = $wnd->Frame( 
        #-height      => 2,
        #-bg          => 'black',
        #-borderwidth => 3,
    #)->pack();
    #
	my $btn;

    $btn = $wnd->Button( 
       -text => '',
       -width  => 20,
       -height => 1,
    )->pack();

    my $me = $wnd->MatchEntry(
           -choices        => \@projects,
           -fixedwidth     => 1, 
           -ignorecase     => 1,
           -maxheight      => 1,
           -entercmd       => sub { print "callback: -entercmd\n"; }, 
           -onecmd         => sub { print "callback: -onecmd  \n"; }, 
           -tabcmd         => sub { print "callback: -tabcmd  \n"; }, 
           -zerocmd        => sub { print "callback: -zerocmd \n"; },
    )->pack(
        -side => 'left', 
        -padx => 0
    );

    $btn = $wnd->Button( 
       -text => '',
       -width  => 20,
       -height => 1,
    )->pack();

    return $self;
}

sub wnd_frame_build { 
    my ($self, $wnd) = @_;
    $wnd ||= $self->{mw};

    $wnd->Label( 
        -text   => 'Build', 
        -height => 2,
    )->pack;

    my $fr_build = $wnd->Frame()->pack(
        -side => 'top', 
        -fill => 'x'
    );

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

sub wnd_frame_view { 
    my ($self, $wnd) = @_;

    $wnd ||= $self->{mw};

    $wnd->Label( 
        -text => 'View', 
        -height => 2,
    )->pack;

    my $fr_view = $wnd->Frame()->pack(-side => 'top', -fill => 'x');

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



1;
 

