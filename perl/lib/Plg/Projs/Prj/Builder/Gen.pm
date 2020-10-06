
package Plg::Projs::Prj::Builder::Gen;

use utf8;

use strict;
use warnings;

use String::Util qw(trim);

use Data::Dumper qw(Dumper);
use Base::Data qw(
	d_str_split_sn
	d_path
);

binmode STDOUT,':encoding(utf8)';

sub _gen_preamble {
    my ($bld) = @_;

    my $on = $bld->_val_list_ref_('sii generate on');
    my $sec = 'preamble';

    return () unless grep { /^$sec$/ } @$on;
    my @lines;

    my $data = $bld->_sct_data($sec);

    return @lines;
}

sub _gen_preamble_packages {
    my ($bld) = @_;

    my $on = $bld->_val_list_ref_('sii generate on');
    my $sec = 'preamble.packages';

    return [] unless grep { /^$sec$/ } @$on;
    my @lines;

    my $packs = $bld->_val_list_ref_('sii generate on');

    my $data = $bld->_sct_data($sec);
	my $pack_opts = d_path($data,'pkg pack_opts',{});

	my @contents = d_str_split_sn($data,'contents');
	foreach (@contents) {
		/^pkg$/ && do {
			my @pack_list = d_str_split_sn($data,'pkg pack_list');
			foreach my $pack (@pack_list) {
				my $s_o = $pack_opts->{$pack} || '';
				$s_o = join "," => map { trim($_) } split("\n",$s_o);
				
				my $o = $s_o ? qq{[$s_o]} : '';
		
				local $_ = sprintf('\usepackage%s{%s}',$o,$pack);
		
				push @lines,$_ if length;
			}
			next;
		};

		/^ii$/ && do {
			my @ii = d_str_split_sn($data,'ii');
			foreach my $ii_sec (@ii) {
				local $_ = sprintf('\ii{%s}',$ii_sec);
				push @lines,$_;
			}
			next;
		};
		
	}

    #print Dumper(@lines) . "\n";


    return @lines;
}

1;

