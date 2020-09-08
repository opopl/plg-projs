#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use Tk;

# Main Window
my $mw = new MainWindow;
#Text Area
my $txt = $mw -> Text(-width=>40, -height=>10);
my $srl_y = $mw -> Scrollbar(-orient=>'v',-command=>[yview => $txt]);
my $srl_x = $mw -> Scrollbar(-orient=>'h',-command=>[xview => $txt]);
$txt -> configure(-yscrollcommand=>['set', $srl_y], 
		-xscrollcommand=>['set',$srl_x]);

#Geometry Management
$txt -> grid(-row=>1,-column=>1);
$srl_y -> grid(-row=>1,-column=>2,-sticky=>"ns");
$srl_x -> grid(-row=>2,-column=>1,-sticky=>"ew");

MainLoop;
