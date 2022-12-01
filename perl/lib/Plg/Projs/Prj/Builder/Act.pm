
package Plg::Projs::Prj::Builder::Act;

use utf8;

binmode STDOUT,':encoding(utf8)';

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use File::Spec::Functions qw(catfile);

sub _acts {
    my ($bld) = @_;

    my @acts = sort keys %{$bld->{maps_act} || {}};

    return @acts;
}

sub act_dump_bld {
    my ($bld) = @_;

    my $data = $bld->_opt_argv_('data','');

    $bld->dump_bld($data);
    exit 0;
}

sub act_show_acts {
    my ($bld) = @_;

    foreach my $acts ($bld->_acts) {
        print $acts . "\n";
    }

    exit 0;
}

sub act_db_push {
    my ($bld) = @_;

    my $rmt = $ENV{rmt};
    unless ($rmt) {
        warn 'no rmt!' . "\n";
        return $bld;
    }
    my $rmt_dir;
    $rmt_dir = catfile(qw(/mnt usb),$rmt) if $^O eq 'linux';
    $rmt_dir = catfile(qw(/Volumes),$rmt) if $^O eq 'darwin';
    unless (-d $rmt_dir) {
        warn 'rmt not mounted: ' . $rmt . "\n";
        return $bld;
    }
    my $rmt_db_dir = catfile($rmt_dir,qw(db));
    unless (-d $rmt_db_dir) {
        mkpath $rmt_db_dir;
    }

    return $bld;
}

sub act_show_trg {
    my ($bld) = @_;

    foreach my $trg ($bld->_trg_list) {
        print $trg . "\n";
    }
    exit 0;
}

1;


