
package Plg::Projs::Build::Maker::Jnd;

use strict;
use warnings;

use utf8;

binmode STDOUT,':encoding(utf8)';

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Plg::Projs::Tex::Gen;
use Plg::Projs::Tex qw(
    texify
);

use String::Util qw(trim);
use Base::Arg qw(
    hash_inject
    hash_apply
);

use Capture::Tiny qw(
    capture_merged
);
use File::stat;
use File::Path qw( mkpath rmtree );
use File::Copy qw( copy );
use Data::Dumper qw(Dumper);

use Base::DB qw(
    dbh_select
    dbh_select_first
);

use Plg::Projs::Build::Maker::Jnd::Processor;


sub cmd_jnd_compose {
    my ($mkr) = @_;

    # Plg::Projs::Build::Maker
    $mkr
        ->cmd_json_out_runtex
        ->cmd_join
        ->copy_to_src
        ->create_bat_in_src
        ;

    my $root = $mkr->{root};
    my $proj = $mkr->{proj};

    my $jfile     = $mkr->_file_joined;
    my $jfile_ht  = $mkr->_file_joined_ht;

    my $prc = Plg::Projs::Build::Maker::Jnd::Processor->new(
        jfile => $jfile,
        root  => $root,
        proj  => $proj,
        mkr   => $mkr,
    );

    $prc
        ->f_read
        ->loop
        ->f_write
        ;

    copy($jfile, $jfile_ht);
    my $cfg = $mkr->{bld}->_sec_file({ 'sec' => 'cfg' });
    if (-f $cfg) {
        my $cfg_ht = catfile($mkr->{src_dir},'jnd_ht.cfg');
        copy($cfg, $cfg_ht);
    }

    return $mkr;
}

###jnd_compose

=head3 cmd_jnd_build

=head4 Calls

cmd_jnd_compose

=cut

###jnd_build
sub cmd_jnd_build {
    my ($mkr) = @_;

    my $proj    = $mkr->{proj};
    my $src_dir = $mkr->{src_dir};

    my $proj_pdf_name = $mkr->{pdf_name} || $proj;

    mkpath $mkr->{src_dir} unless -d $mkr->{src_dir};

    $mkr->cmd_jnd_compose;

    my $pdf_file = catfile($src_dir,'jnd.pdf');

    chdir $src_dir;
    my $ext = $^O eq 'MSWin32' ? 'bat' : 'sh';
    my $cmd = sprintf(q{_run_tex.%s -x %s},$ext, $mkr->{tex_exe});
    system($cmd);

    my @dest;
    push @dest,
        $mkr->{out_dir_pdf}
        ;

    if (-e $pdf_file) {
        while (1) {
            my $st = stat($pdf_file);

            unless ($st->size) {
                die "Zero File Size: $pdf_file" . "\n";
                last;
            }

            foreach(@dest) {
                mkpath $_ unless -d;

                my $d = catfile($_, $proj_pdf_name . '.pdf');

                print "Copied PDF File to:" . "\n";
                print "     " . $d . "\n";

                copy($pdf_file, $d);
            }

            last;
        }
    }
    chdir $mkr->{root};

    return $mkr;

}



1;


