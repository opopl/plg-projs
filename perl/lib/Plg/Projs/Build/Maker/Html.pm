
package Plg::Projs::Build::Maker::Html;

use utf8;
use strict;
use warnings;

sub _sec_link_html {
	my ($mkr,$ref) = @_;
	$ref ||= {};

	my ($sec, $proj, $link_title) = @{$ref}{qw( sec proj link_title )};

	my $sec_loc = sprintf('../_buf.%s/jnd_ht.html', $sec);
	my $link = sprintf('\href{%s}{%s}', $sec_loc, $link_title );

	return $link;
}

1;
 

