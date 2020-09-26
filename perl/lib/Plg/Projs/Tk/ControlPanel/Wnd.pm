
package Plg::Projs::Tk::ControlPanel::Wnd;

use strict;
use warnings;

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
#'expr'  => 'projs#vim_server#async_build_bare()'
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

sub wnd_fill_projects_entry {
    my ($self, $wnd) = @_;

    my $prj = $self->{prj};
    my $mw  = $self->{mw};

    my @projects = $prj->_projects;

    my $fr = $wnd->Frame( 
        -height      => 2,
        -bg          => 'black',
        -borderwidth => 3,
    );

    my $me = $wnd->MatchEntry(
           -choices        => \@projects,
           -fixedwidth     => 1, 
           -ignorecase     => 1,
           -maxheight      => 5,
           -entercmd       => sub { print "callback: -entercmd\n"; }, 
           -onecmd         => sub { print "callback: -onecmd  \n"; }, 
           -tabcmd         => sub { print "callback: -tabcmd  \n"; }, 
           -zerocmd        => sub { print "callback: -zerocmd \n"; },
    )->pack(-side => 'left', -padx => 50);

    return $self;
}


1;
 

