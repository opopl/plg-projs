#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use File::Spec::Functions qw(catfile);
use File::Slurp::Unicode;
use Data::Dumper qw(Dumper);

my $cmd   = shift @ARGV;
my $class = shift @ARGV || 'book';

my $tmp_dir  = $ENV{TMP};

my $tex_file = catfile($tmp_dir,q{show_cmd.tex});


my $tex_exe = 'pdflatex' ;
my @tex_opts=( 
    '-interaction=nonstopmode', 
    #'-file-line-error',
    '-output-directory=' . $tmp_dir
);

$tex_exe = join(" ",$tex_exe, @tex_opts);

my $tex_code = q{
\documentclass{%s}
\begin{document}
\makeatletter
\show%s
\makeatother
\end{document}
};

$tex_code = sprintf($tex_code, $class, $cmd);

write_file($tex_file,$tex_code . "\n");

my @lines = `$tex_exe $tex_file`;

$cmd =~ s/^\s*//g;
$cmd =~ s/\s*$//g;

my @def;
my $is_def;

my $i=0;
foreach(@lines) {
    chomp;

    #print $_ . "\n";

    /^\s*>\s*\Q$cmd\E=(.*)$/ && do {
        $is_def = 1;
        $i=0;
        push @def, $1;
        next;
    };

    /^l\.\d+/ && do {
        $is_def = 0 if $is_def;
        if (@def) {
            $def[-1] =~ s/\.\s*$//g;
        }
        next;
    };

    if ($is_def) {
        $i++;
        if ($i==1) {
            s/^->//g;
        }
        push @def, $_;
    }

}

for(@def){
    print $_ . "\n";
}

#my $out;
#do {
    #local *STDOUT;
    #open STDOUT, ">>", \$out;
#};
#print "written to original STDOUT\n";

#print "written to the variable\n";

