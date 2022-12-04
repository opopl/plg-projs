
package Plg::Projs::Build::Maker::Html;

use utf8;
use strict;
use warnings;

sub _sec_link_html {
    my ($mkr,$ref) = @_;
    $ref ||= {};

    my ($sec, $proj, $link_title) = @{$ref}{qw( sec proj link_title )};
    my $target = $ref->{target} || '_buf.' . $sec;

    my $color = $ref->{color};

    my $sec_loc = sprintf('../%s/jnd_ht.html', $target);
    my $link = sprintf('\href{%s}{%s}', $sec_loc, $link_title );

    if ($color) {
        $link = sprintf('\color{%s}{%s}', $color, $link);
    }

    $link .= '\par' if $ref->{par};

    $DB::single = 1;1;

    return $link;
}

1;
 

