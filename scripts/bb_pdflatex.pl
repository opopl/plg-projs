#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use Cwd;

use base qw( Plg::Projs::Build::PdfLatex );

__PACKAGE__
    ->new( root => getcwd() )
    ->run;
