#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use File::Spec::Functions qw(catfile);

my $cmd = shift @ARGV;

my $tmp_dir = catfile($ENV{TMP},q{show_cmd.tex});

my $class = 'book';

my $tex = q{
\documentclass{%s}
\begin{document}
\show%s
\end{document}
};

$tex = sprintf($tex, $class, $cmd);
