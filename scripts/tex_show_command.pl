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

my $tmp_dir  = $ENV{TMP} || catfile( $ENV{HOME}, qw(tmp) );
mkpath $tmp_dir unless -d $tmp_dir;

my $tex_file = catfile($tmp_dir,q{show_cmd.tex});


my $tex_exe = 'pdflatex' ;
my @tex_opts=( 
    '-interaction=nonstopmode', 
    #'-file-line-error',
    '-output-directory=' . $tmp_dir
);

$tex_exe = join(" ",$tex_exe, @tex_opts);

my $preamble = q{
\usepackage{ifpdf}
\usepackage{ifxetex}

\usepackage{xparse}
\usepackage{titletoc}

\usepackage{mathtext}

\usepackage[OT1,T2A,T3]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage[english,russian]{babel}

\usepackage{iflang}

\usepackage[titles]{tocloft}
\usepackage{nameref}

\usepackage{color,xcolor,colortbl}

\usepackage[xindy]{imakeidx}
\usepackage{etoolbox}

\usepackage[ %
  colorlinks=true,
  linktoc=all,
  linkcolor=blue,
  letterpaper, %
  unicode, %
  linktocpage, %
  bookmarksdepth=subparagraph,%
  bookmarksnumbered=true,%
]{hyperref}
%hyperindex=false,%

\usepackage{bookmark}
\usepackage[hmargin={1cm,1cm},vmargin={2cm,2cm},centering]{geometry}
\usepackage[export]{adjustbox}

\usepackage{ifthen}
\usepackage{longtable}
\usepackage{graphicx}
\usepackage{projs}
\usepackage{multicol}
\usepackage{pgffor}
\usepackage{multicol}
\usepackage{filecontents}
\usepackage{tikz,pgffor}

\usepackage[useregional]{datetime2}

};

my $tex_code = q{
\documentclass{%s}
%s

\begin{document}
\makeatletter
\show%s
\makeatother
\end{document}
};

$tex_code = sprintf($tex_code, $class, $preamble, $cmd);

write_file($tex_file,$tex_code . "\n");

my @lines = `$tex_exe $tex_file`;

$cmd =~ s/^\s*//g;
$cmd =~ s/\s*$//g;

my @def;
my $is_def;

my $i = 0;
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

