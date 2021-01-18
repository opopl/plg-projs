#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use URI;
use Web::Scraper;
use Encode;

use File::Basename qw(basename dirname);
use FindBin qw($Bin $Script);

unless (@ARGV) {
	die "USAGE: \n$Script URI";
}

my $uri = shift @ARGV;

# First, create your scraper block
my $authors = scraper {
    # Parse all TDs inside 'table[width="100%]"', store them into
    # an array 'authors'.  We embed other scrapers for each TD.
    process 'table[width="100%"] td', "authors[]" => scraper {
      # And, in each TD,
      # get the URI of "a" element
      process "a", uri => '@href';
      # get text inside "small" element
      process "small", fullname => 'TEXT';
    };
};

my $res = $authors->scrape( URI->new($uri) );

# iterate the array 'authors'
for my $author (@{$res->{authors}}) {
    # output is like:
    # Andy Adler      http://search.cpan.org/~aadler/
    # Aaron K Dancygier       http://search.cpan.org/~aakd/
    # Aamer Akhter    http://search.cpan.org/~aakhter/
    print Encode::encode("utf8", "$author->{fullname}\t$author->{uri}\n");
}
