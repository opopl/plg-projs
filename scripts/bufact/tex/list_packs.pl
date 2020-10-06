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

my $is_pack;
my @ot;

sub pack_add {
    my ($p,$o) = @_;

    my @p = split "," => $p;
    push @pack_list, @p;

    return unless $o;

    my @opts = split "," => $o;

    foreach my $pack (@p) {
        $pack_opts{$pack} ||= [];

        push @{$pack_opts{$pack}}, $o; 
    }
}

while (@lines) {
    local $_ = shift @lines;
    chomp;

    m/^\\usepackage(?:|\[(?<opts>.*)\])\{(?<packs>.*)\}/ && do {
        pack_add($+{qw(packs opts)});

        next;
    };

    m/^\\usepackage\[(?<opts>[^]]*)$/ && do {
        push @ot, $+{opts};
        $is_pack = 1;
        next;
    };

    if ($is_pack) {
        m/^\s*\]\{(?<packs>.*)\}$/ && do {
            $is_pack = 0;
            next;
        };

        push @ot, $_;
    }
}

@pack_list = uniq(\@pack_list);

print Dumper(\@pack_list) . "\n";
print Dumper(\%pack_opts) . "\n";
print Dumper(\@ot) . "\n";

