#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use XML::LibXML;

use Data::Dumper qw(Dumper);
use FindBin qw($Bin $Script);

unless (@ARGV) {
    my $h = qq{
        LOCATION
            $0
        USAGE
            perl $Script FILE XPATH
    };
    print $h . "\n";
    exit 0;
}

my ($file, $xpath)  = @ARGV;

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

my @lines;
$dom->findnodes($xpath)->map(sub {
        my ($n) = @_;
        push @lines, $n->toString;
    }
);

my $t = join("\n", @lines);
print $t . "\n";

# save
#open my $out, '>:encoding(utf8)', 'out.xml';
#binmode $out; # as above
#$dom->toFH($out);

