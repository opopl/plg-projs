#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use base qw( Plg::Projs::Scripts::IndInsBmk );

__PACKAGE__->new->ind_ins_bmk;
