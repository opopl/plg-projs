#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use File::Spec::Functions qw(catfile);
use File::Slurp::Unicode;

my $cmd = shift @ARGV;

my $tmp_file = catfile($ENV{TMP},q{show_cmd.tex});

my $class = 'book';

my $tex = q{
\documentclass{%s}
\begin{document}
\show%s
\end{document}
};

$tex = sprintf($tex, $class, $cmd);

write_file($tmp_file,$tex . "\n");
