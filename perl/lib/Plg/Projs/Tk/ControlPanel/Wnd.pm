
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


1;
 
