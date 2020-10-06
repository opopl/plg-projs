#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use File::Slurp::Unicode;

my $file = shift @ARGV;

my @lines=read_file $file;
for (@lines) {
	chomp;
}
