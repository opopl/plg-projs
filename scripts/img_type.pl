#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use FindBin qw($Bin $Script);

use Image::Info qw(
	image_type
);

unless (@ARGV) {
	print qq{
		USAGE:
			perl $Script FILE
	} . "\n";
	exit 0;
}

my $file = shift @ARGV;

my $itp = image_type($file);

print Dumper($itp) . "\n";