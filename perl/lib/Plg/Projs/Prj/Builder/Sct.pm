
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
    str_split
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
    #$DB::single = 1 if $sec eq 'index';

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
            push @lines, $res;
            next;
        };
        /^\@perlfile\{(.*)\}$/ && do {
            my $pl = $1;
            if (-e $pl) {
                my $res = do $pl;
                push @lines, $res;
            }
            next;
        };
###@pkg
        /^\@pkg$/ && do {
            my @pack_list = d_str_split_sn($data,'pkg pack_list');
            foreach my $pack (@pack_list) {
                next unless $pack;

                my $s_o = $pack_opts->{$pack} || '';
                my @o = str_split_sn($s_o);

                $s_o = join(',' => @o);
                
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
            push @lines, @txt;

            next;
        };

        push @lines,$_;

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

    my ($scts, @data, $data);

    $scts = $bld->_val_('sii scts') || [];
    if (ref $scts eq 'HASH') {
        $data = $scts->{$sec};

    } elsif (ref $scts eq 'ARRAY') {
        @data = map { $_->{name} eq $sec ? $_ : () } @$scts;

        foreach my $x (@data) {
            while(my($k,$v) = each %$x){
                $data->{$k} = $v;
            }
        }
    }

    return $data;
}

1;
 

