
package Plg::Projs::Prj::Builder::Out;

use strict;
use warnings;
use utf8;

use FindBin qw($Bin $Script);

use Data::Dumper qw(Dumper);
use File::Find::Rule;

my @opts;
push @opts, qw( -quality 100);
push @opts, qw( -density 300);
push @opts, qw( -background white);
push @opts, qw( -alpha remove);
my $opts = join(" ", @opts);

sub pdf2img {
    my ($bld, $ref) = @_;
    $ref ||= {};
    my $target = $ref->{target} || $bld->{target};
    my $proj = $ref->{proj} || $bld->{proj};

    my $rule = File::Find::Rule->new;
    $rule->name('out_*.pdf');
    #$rule->maxdepth($max_depth) if $max_depth;

    #$rule->exec( sub {
       #my ($shortname, $path, $fullname) = @_;
    #})
       #
    my @pdf_files = $rule->in('.');
    foreach my $pdf_file (@pdf_files) {
        next unless -f $pdf_file;

        (my $img_file = $pdf_file) =~ s/\.pdf$/.png/g;

        my $cmd = qq{ convert $opts $pdf_file $img_file };
        print qq{ convert: $pdf_file => $img_file } . "\n";
        system("$cmd");
    }

}

1;

