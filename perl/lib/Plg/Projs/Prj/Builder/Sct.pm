
package Plg::Projs::Prj::Builder::Sct;

use utf8;

use strict;
use warnings;

use String::Util qw(trim);
use Data::Dumper qw(Dumper);

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
###@input
        /^\@input$/ && do {
            my @input = d_str_split_sn($data,'input');
            foreach my $sec (@input) {
                local $_ = sprintf('\input{%s}',$sec);
                push @lines,$_;
            }
            next;
        };
###@makeindex
        /^\@makeindex$/ && do {
            my $mi = d_path($data,'makeindex');
            my $mis = sub { my ($x) = @_;
                my @opts;
                while(my($k,$v)=each %{$x}){
                    next unless $v;
                    push @opts, join("=", $k, $v);
                }
                my $o = @opts ? sprintf('[%s]', join("," => @opts)) : '';
                local $_ = sprintf('\makeindex%s',$o);
                push @lines,$_;
            };

            if (ref $mi eq "ARRAY"){
                foreach my $x (@$mi) {
                    $mis->($x);
                }
            }elsif(ref $mi eq "HASH"){
                $mis->($mi);
            }
            #foreach my $sec (@input) {
            #}
            next;
        };
###@perl
        /^\@perl$/ && do {
            my $pl = d_path($data,'perl');
            my @w;
            local $SIG{__WARN__} = sub { push @w,@_; };
            my $res = eval $pl;
            if ($@){
                warn $@ . "\n";
            }
            push @lines,$res;
            next;
        };
        /^\@perlfile\{(.*)\}$/ && do {
            my $pl = $1;
            if (-e $pl) {
                my $res = do $pl;
                push @lines,$res;
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
            while(@txt){
                local $_ = shift @txt;

                s/\@var\{(\w+)\}/$bld->_bld_var($1)/ge; 
                s/\@env\{(\w+)\}/$bld->_bld_env($1)/ge; 

                push @lines, $_;
            }
            next;
        };

        push @lines,$_;

    }
    return @lines;

}

sub _bld_var {
    my ($bld, $var) = @_;

    my $val = $bld->_val_('vars ' . $var) || '';
    return $val;
}

sub _bld_env {
    my ($bld, $var) = @_;

    my $val = $ENV{$var} || '';
    return $val;
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
 

