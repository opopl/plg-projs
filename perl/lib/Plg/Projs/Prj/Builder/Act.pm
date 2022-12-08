
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
    return $bld;
}

sub act_show_acts {
    my ($bld) = @_;

    foreach my $acts ($bld->_acts) {
        print $acts . "\n";
    }

    return $bld;
}

sub act_db_pull {
    my ($bld, $ref) = @_;

    $bld->act_db_sync({ pull => 1 });
    return $bld;
}

sub act_db_push {
    my ($bld, $ref) = @_;

    $bld->act_db_sync({ push => 1 });
    return $bld;
}

sub act_db_sync {
    my ($bld, $ref) = @_;
    $ref ||= {};

    my ($push, $pull, $rmt) = @{$ref}{qw( push pull rmt )};

    my $root_id = $bld->{root_id};

    unless ($rmt) {
        my @rmt;
        my @df = `df`;
        for(@df){
            chomp;
            my @line = split /\s+/;
            my $last = pop @line;
            my $re;
            if ($^O eq 'linux') {
                $re = qr|^\/mnt\/usb\/(\w+)|;
            } elsif ($^O eq 'darwin') {
                $re = qr|^\/Volumes\/(\w+)|;
            }
            next unless $re && $last =~ m|$re|;
            push @rmt, $1;
        }

        if (@rmt) {
            $bld->act_db_sync({ %$ref, rmt => $_ }) for(@rmt);
            return $bld;
        }
    }

    $DB::single = 1;
    unless ($rmt) {
        warn 'no rmt!' . "\n";
        return $bld;
    }
    my $rmt_dir;
    $rmt_dir = catfile(qw(/mnt usb),$rmt) if $^O eq 'linux';
    $rmt_dir = catfile(qw(/Volumes),uc $rmt) if $^O eq 'darwin';
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

    my ($m_local, $m_remote) = map {
            my $f = $dbf{$_};
            -f $f ? stat($f)->mtime : 0
        } qw(local remote);

    unless($push || $pull) {
        $push = ( $m_local > $m_remote ) ? 1 : 0;
        $pull = !$push ? 1 : 0;
    }
    $DB::single = 1;

    if ($push ) {
        print qq{ db PUSH: local => remote } . "\n";
        copy(@dbf{qw(local remote)});
    } elsif ($pull) {
        print qq{ db PULL: remote => local } . "\n";
        copy(@dbf{qw( remote local )});
    }

    return $bld;
}

sub act_show_trg {
    my ($bld) = @_;

    foreach my $trg ($bld->_trg_list) {
        print $trg . "\n";
    }
    return $bld;
}

1;


