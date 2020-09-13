#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use Prima qw(Notebooks Buttons Application);
my $nb = Prima::TabbedNotebook->new(
   tabs => [ 'First page', 'Second page', 'Second page' ],
   size => [ 300, 200 ],
);

$nb->insert_to_page( 1, 'Prima::Button' );
$nb->insert_to_page( 2,
   [ 'Prima::Button', bottom => 10  ],
   [ 'Prima::Button', bottom => 150 ],
);
$nb->Notebook->backColor( cl::Green );
run Prima;
