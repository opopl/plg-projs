#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use File::Slurp::Unicode;
use Data::Dumper qw(Dumper);

use Base::List qw(uniq);
use Base::XML::Dict qw(dict2xml);

use XML::LibXML;
use XML::LibXML::PrettyPrint;

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

    my @opts = opts_split($o);

    foreach my $pack (@p) {
        $pack_opts{$pack} ||= [];

        push @{$pack_opts{$pack}}, 
            ref $o eq 'ARRAY' ? @$o : $o; 
    }
}

sub opts_split {
    my ($o) = @_;

    return @$o if ref $o eq 'ARRAY';

    my @opts = map { 
        s/\s*$//g; 
        s/^\s*//g; 
        s/[%]*$//g; 
        length ? $_ : () 
    } split "," => $o;

    return @opts;
}

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

my $pp = XML::LibXML::PrettyPrint->new(
    indent_string => " ",
    element => {
        block => [qw( pack_list )]
    }
);
$pp->pretty_print($doc); 
print $doc->toString;

#print Dumper($h) . "\n";

