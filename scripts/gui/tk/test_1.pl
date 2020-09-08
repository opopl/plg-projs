#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use Tk qw/tkinit/;
use Tk::Pane;

my $mw = Tk::MainWindow->new;
my $topleft  = $mw->Pane(qw'-bg pink'   )->grid(qw/ -column 0 -row 0 /);
my $topright = $mw->Pane(qw'-bg purple' )->grid(qw/ -column 1 -row 0 /);
my $botleft  = $mw->Pane(qw'-bg green'  )->grid(qw/ -column 0 -row 1 /);
my $botright = $mw->Pane(qw'-bg orange' )->grid(qw/ -column 1 -row 1 /);
my $botright = $mw->Pane(qw'-bg orange' )->grid(qw/ -column 2 -row 2 /);
$mw->MainLoop;
