
package Plg::Projs::Prj::Builder::Sct;

use utf8;

use strict;
use warnings;

use String::Util qw(trim);

use Base::Data qw(
    d_str_split_sn
    d_str_split
    d_path
);

sub _sct_lines {
    my ($bld, $sec) = @_;

    my $data = $bld->_sct_data($sec);
    my $pack_opts = d_path($data,'pkg pack_opts',{});

    my @lines;

    my @contents = d_str_split_sn($data,'contents');
    foreach (@contents) {
###@doc
        /^\@doc$/ && do {
            my $doc   = d_path($data,'doc');

            my $opts  = $doc->{opts} || '';
            my $class = $doc->{class} || '';

            my $o = $opts ? qq{[$opts]} : '';

            local $_ = sprintf('\documentclass%s{%s}',$o,$class);
            push @lines,$_;
            next;
        };
###@setcounter
        /^\@setcounter$/ && do {
            my $stc = d_path($data,'setcounter');
            while(my($k,$v)=each %$stc){
                local $_ = sprintf('\setcounter{%s}{%s}',$k,$v);
                push @lines,$_;
            }

            next;
        };
###@ii
        /^\@ii$/ && do {
            my @ii = d_str_split_sn($data,'ii');
            foreach my $ii_sec (@ii) {
                local $_ = sprintf('\ii{%s}',$ii_sec);
                push @lines,$_;
            }
            next;
        };
###@pkg
        /^\@pkg$/ && do {
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
###@txt
        /^\@txt$/ && do {
            my @txt = d_str_split($data,'txt');
            push @lines, @txt;
            next;
        };

        push @lines,$_;

    }
    return @lines;

}

sub _sct_data {
    my ($bld, $sec) = @_;

    my $scts = $bld->_val_('sii scts') || [];
    my @data = map { $_->{name} eq $sec ? $_ : () } @$scts;

    my %data;
    foreach my $x (@data) {
        while(my($k,$v) = each %$x){
            $data{$k} = $v;
        }
    }

    return {%data};
}

1;
 

