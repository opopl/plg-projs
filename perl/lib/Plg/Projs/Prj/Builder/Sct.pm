
package Plg::Projs::Prj::Builder::Sct;

use utf8;

use strict;
use warnings;

use Cwd qw(getcwd);
use String::Util qw(trim);
use Data::Dumper qw(Dumper);

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Base::String qw(
    str_split_sn
);

use Base::Data qw(
    d_str_split_sn
    d_str_split
    d_path
);

=head3 _sct_lines

=head4 Usage

    my @lines = $bld->_sct_lines($sec);

=head4 Call tree

    _gen_sec
        _join_lines

=cut


sub _sct_lines {
    my ($bld, $sec) = @_;

    my $data      = $bld->_sct_data($sec);
    my $pack_opts = d_path($data,'pkg pack_opts',{});

    #print $bld->_bld_var('pagestyle') . "\n";

    my @lines;

    my @contents = d_str_split_sn($data,'contents');
    foreach (@contents) {
###@zero
        /^\@zero$/ && do {
            push @lines,'';
            next;
        };
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
            push @lines, $bld->_bld_ind_makeindex;

            next;
        };
###@printindex
        /^\@printindex$/ && do {
#            my @pi_lines = $bld->_bld_ind_printindex;

            #my $mkr      = $bld->{maker};
            #my $pi_file  = catfile($mkr->{src_dir},qw(print_index.tex));

            #write_file($pi_file,join("\n",@pi_lines) . "\n");

            push @lines, q|\InputIfFileExists{print_index.tex}{}{}|;

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
        /^\@txt(?:|\.(.*))$/ && do {
            my $p = $1 // '';
            $p =~ s/\./ /g;

            my @txt = d_str_split($data,'txt ' . $p );
            $bld->_txt_expand({ txt_lines => \@txt });
            push @lines,@txt;

            next;
        };

        push @lines,$_;

    }
    return @lines;

}

sub _bld_ind {
    my ($bld) = @_;
    my $ind = $bld->_val_('preamble index ind');
    return $ind;
}

sub _bld_ind_makeindex {
    my ($bld) = @_;

    my $ind_mk = sub { 
        my ($x) = @_;
        my @opts;
        while(my($k,$v)=each %{$x}){
            next unless $v;
            push @opts, join("=", $k, $v);
        }
        my $o = @opts ? sprintf('[%s]', join("," => @opts)) : '';
        local $_ = sprintf('\makeindex%s',$o);
        return $_;
    };

    my @lines = $bld->_bld_ind_lines($ind_mk);
    return @lines;
}

sub _bld_ind_printindex {
    my ($bld) = @_;

    my $sub_ind_pr = sub { 
        my ($x) = @_;

        my $name  = $x->{name};
        my $title = $x->{title};

        my $idx_file = $name ? qq{$name.idx} : qq{jnd.idx};

        print qq{$idx_file} . "\n";
        print getcwd() . "\n";
        return unless -e $idx_file;

#\printindex[$name]
#\InputIfFileExists{%s.ind}{}{}
        my $t = q{
\cleardoublepage
\phantomsection
\addcontentsline{toc}{chapter}{%s}
\printindex%s
        };

        my $s_title = $title ? $title : '\indexname';
        my $s_name  = $name ? qq{[$name]} : '';

        $t = sprintf($t, $s_title, $s_name );
        return $t;
    };

    my @lines = $bld->_bld_ind_lines($sub_ind_pr);
    return @lines;
}

sub _bld_ind_lines {
    my ($bld,$sub) = @_;

    my $ind = $bld->_bld_ind;
    return () unless $ind;

    my @lines;

    if (ref $ind eq "ARRAY"){
        foreach my $x (@$ind) {
            my $s = $sub->($x);
            push @lines, $s if $s;
        }
    }elsif(ref $ind eq "HASH"){
        my $s = $sub->($ind);
        push @lines, $s if $s;
    }
    return @lines;
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
 

