#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use File::Slurp::Unicode;
use Data::Dumper qw(Dumper);

use Base::List qw(uniq);
use Base::XML::Dict qw(dict2xml);
use Base::XML qw(xml_pretty);

use XML::LibXML;
use XML::LibXML::PrettyPrint;

my $file = shift @ARGV;

my @lines = read_file $file;

my @pack_list;
my %pack_opts;

my $is_pack;
my @ot;

while (@lines) {
    local $_ = shift @lines;
    chomp;

    next if /^\s*%/;

    m/^\\usepackage(?:|\[(?<opts>.*)\])\{(?<packs>.*)\}/ && do {
        pack_add(@+{qw(packs opts)});

        next;
    };

    # start of package
    m/^\\usepackage\[(?<opts>[^]]*)$/ && do {
        push @ot, opts_split($+{opts});
        $is_pack = 1;
        next;
    };

    if ($is_pack) {

        # end of package
        m/^\s*\]\{(?<packs>.*)\}$/ && do {
            $is_pack = 0;
            pack_add(@+{qw(packs)},\@ot);
            next;
        };

        push @ot, opts_split($_);
    }
}

@pack_list = uniq(\@pack_list);

my $p_opts = {};
my $p_list = join("\n" => @pack_list);
while(my($k,$v) = each %pack_opts){
    $p_opts->{$k} = join("\n",@$v);
}

my $h = {
    packs => {
        pack_list => $p_list,
        pack_opts => $p_opts,
    }
};

my $doc = dict2xml($h,doc => 1);

my @ids = qw(pack_list);
push @ids,@pack_list;

my $xml = xml_pretty($doc,ids => [@ids]);
print $xml . "\n";
