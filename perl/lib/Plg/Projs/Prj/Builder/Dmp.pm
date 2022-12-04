
package Plg::Projs::Prj::Builder::Dmp;

use utf8;
use strict;
use warnings;

use JSON::Dumper::Compact 'jdc';
use Clone qw(clone);
use JSON::XS;

use Base::Arg qw(
    obj_exe_cb
);

binmode STDOUT,':encoding(utf8)';

use Data::Dumper qw(Dumper);

sub dump_trg {
    my ($bld, $target) = @_;
    $target //= $bld->{target};

    my $ht = $bld->_val_('targets',$target) || {};
    print Dumper($ht) . "\n";
    return $bld;
}

sub dump_bld {
    my ($bld, $path) = @_;

    $path =~ s/^['"]*//g;
    $path =~ s/['"]*$//g;

    my $h = $bld->_vals_($path);
    my $data = ref $h eq 'HASH' ? { map { $_ => $h->{$_} } keys %$h } : $h;
    my $format = $bld->{opt}->{format} || 'perl';

    my $subs = {
        'perl' => sub {
            print sprintf('path: %s',$path) . "\n";
            print Dumper($data) . "\n";
        },
        'json' => sub {
            my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

            my $cdata = clone($data);
            my $cb = sub {
                my ($val) = @_;
                $val = '@CODE@' if ref $val eq 'CODE';
                return $val;
            };
            $cdata = obj_exe_cb($cdata, $cb);
            my $j_data;
            $j_data = eval { $coder->encode($cdata); };
            #warn $@ if $@;
            #$j_data = eval { jdc($cdata); };
            my @out;
            if ($j_data) {
                push @out, 'begin_json', $j_data, 'end_json';
                print join("\n",@out) . "\n";
            }
        }
    };
    my $sub = $subs->{$format};
    $sub->() if $sub;

    return $bld;
}


1;


