#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use base qw(
	Plg::Projs::Scripts::MkInd
);

__PACKAGE__->new->run;
