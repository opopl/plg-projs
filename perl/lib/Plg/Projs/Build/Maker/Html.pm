
package Plg::Projs::Build::Maker::Html;

use utf8;
use strict;
use warnings;

sub _sec_link_html {
    my ($mkr,$ref) = @_;
    $ref ||= {};

    my $bld = $mkr->{bld};

    my ($sec, $proj, $link_title) = @{$ref}{qw( sec proj link_title )};
    my $target = $ref->{target} || '_buf.' . $sec;

    my $output = $bld->_trg_output({
          target => $target,
    });
    my $output_ex = -f $output ? 1 : 0;

    my $color = $ref->{color};

    #$color ||= $output_ex ? 'green' : 'red';
    $link_title = sprintf('\textcolor{%s}{%s}', $color, $link_title) if $color;

    my $sec_loc = sprintf('../%s/jnd_ht.html', $target);
    my $link = sprintf('\href{%s}{%s}', $sec_loc, $link_title );

    # my $fbicon = $output_ex ? 'check.mark.white.heavy' : 'exclamation.mark';
    # $link = sprintf('@igg{fbicon.%s} %s', $fbicon, $link) if $fbicon;
    # '✅' => '@igg{fbicon.check.mark.white.heavy}',

    $link .= '\par' if $ref->{par};

    return $link;
}

1;


