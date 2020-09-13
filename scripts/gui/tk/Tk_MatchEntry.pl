#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use Tk;
use Tk::MatchEntry;
 
my $mw = MainWindow->new(-title => "MatchEntry Test");
 
my @choices = [ qw/one one.green one.blue one.yellow two.blue two.green
                   two.cyan three.red three.white three.yellow/ ];
 
$mw->Button->pack(-side => 'left');
 
my $me = $mw->MatchEntry(
       -choices        => @choices,
       -fixedwidth     => 1, 
       -ignorecase     => 1,
       -maxheight      => 5,
       -entercmd       => sub { print "callback: -entercmd\n"; }, 
       -onecmd         => sub { print "callback: -onecmd  \n"; }, 
       -tabcmd         => sub { print "callback: -tabcmd  \n"; }, 
       -zerocmd        => sub { print "callback: -zerocmd \n"; },
   )->pack(-side => 'left', -padx => 50);
 
$mw->Button(-text => 'popup', 
            -command => sub{$me->popup}
           )->pack(-side => 'left');
 
MainLoop;

