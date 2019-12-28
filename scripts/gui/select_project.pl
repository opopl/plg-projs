#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

package main;

use FindBin qw($Bin);
use lib "$Bin/../../perl/lib";

use base qw( Plg::Projs::Dialog::SelectProject );

__PACKAGE__->new->run;

