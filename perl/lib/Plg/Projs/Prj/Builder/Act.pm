
package Plg::Projs::Prj::Builder::Act;

use utf8;

binmode STDOUT,':encoding(utf8)';

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use File::Spec::Functions qw(catfile);
use File::Copy qw(copy move);
use File::stat;

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

    my $root_id = $bld->{root_id};

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
    mkpath $rmt_db_dir unless -d $rmt_db_dir;

    my %dbf = (
        'local'  => $bld->_db_file,
        'remote' => catfile($rmt_db_dir, $root_id . '.db')
    );

    unless (-f $dbf{local}) {
        warn 'no local db! ' . "\n";
        return $bld;
    }

    my ($m_local, $m_remote) = map {
            my $f = $dbf{$_};
            -f $f ? stat($f)->mtime : 0
        } qw(local remote);

    if ($m_local > $m_remote) {
        print qq{ copy db: local => remote } . "\n";
        copy(@dbf{qw(local remote)});
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


