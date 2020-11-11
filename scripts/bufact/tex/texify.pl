#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use Plg::Projs::Tex qw(
    texify
);
use File::Slurp::Unicode;

my $file = shift @ARGV;
my $tex  = read_file $file;

texify(\$tex);

write_file($file,$tex);
