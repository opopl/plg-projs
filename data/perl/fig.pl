#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use base qw(
    Plg::Projs::Prj::Img
);

my $r = {
	tags_img_new => [ qw( _sec_ ) ],
	num_cols     => 1,
	range        => [( 1 .. 1 )],
	width_cell   => 0.3,
	width_last   => 0.5,
	load_pwg     => 1,
};

__PACKAGE__->new(%$r)->run;
