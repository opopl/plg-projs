#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

my $cmd = sprintf("xindy %s",  join(" ",@ARGV));
