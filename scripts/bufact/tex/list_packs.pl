#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use File::Slurp::Unicode;
use Data::Dumper qw(Dumper);

use Base::List qw(uniq);

my $file = shift @ARGV;

my @lines = read_file $file;

my @pack_list;
my %pack_opts;

for (@lines) {
    chomp;
    m/^\\usepackage(?:|\[(?<opts>.*)\])\{(?<packs>.*)\}/ && do {
        my @p = split "," => $+{'packs'};
        push @pack_list, @p;

        if (my $o = $+{opts}) {
            my @opts = split "," => $o;

            foreach my $pack (@p) {
                $pack_opts{$pack} ||= [];

                push @{$pack_opts{$pack}}, $o; 
            }
        }

        next;
    };
}

@pack_list = uniq(\@pack_list);

print Dumper(\@pack_list) . "\n";
print Dumper(\%pack_opts) . "\n";

