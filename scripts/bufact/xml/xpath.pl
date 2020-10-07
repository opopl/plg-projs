#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use XML::LibXML;

use Data::Dumper qw(Dumper);

my $file  = shift @ARGV;
my $xpath = shift @ARGV;

my $prs = XML::LibXML->new;

open my $fh, '<:encoding(utf8)', $file;
binmode $fh;
my $inp = {
    IO              => $fh,
    recover         => 1,
    suppress_errors => 1,
};
my $dom = $prs->load_xml(%$inp);
close $fh;

# save
#open my $out, '>:encoding(utf8)', 'out.xml';
#binmode $out; # as above
#$dom->toFH($out);

