
package Plg::Projs::Prj::Builder::Sct::Index;

use utf8;
use strict;
use warnings;

use Cwd qw(getcwd);

sub _bld_ind {
    my ($bld) = @_;
    my $ind = $bld->_val_('preamble index ind');
    return $ind;
}

sub _bld_ind_makeindex {
    my ($bld) = @_;

    my $ind_mk = sub { 
        my ($bld, $x) = @_;

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
        my ($bld, $x) = @_;

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
            my $s = $sub->($bld, $x);
            push @lines, $s if $s;
        }
    }elsif(ref $ind eq "HASH"){
        my $s = $sub->($bld, $ind);
        push @lines, $s if $s;
    }
    return @lines;
}

1;
 

