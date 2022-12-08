
package Plg::Projs::Build::Maker::Jnd;

use strict;
use warnings;

use utf8;

binmode STDOUT,':encoding(utf8)';

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);
use Cwd;

use File::Find::Rule;

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
use File::Copy qw( copy move );
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

    my $bld = $mkr->{bld};

    my $do_htlatex = $bld->{do_htlatex};
    my $do_box = $bld->{box};

    my $img_dir = $do_box ? catfile($src_dir,qw(imgs)) : '';

    my $target = $bld->{target};

    my $proj_pdf_name = $mkr->{pdf_name} || $proj;

    mkpath $mkr->{src_dir} unless -d $mkr->{src_dir};

    $mkr->cmd_jnd_compose;

    my $pdf_file = catfile($src_dir,'jnd.pdf');
    my $ht_file  = catfile($src_dir,'jnd_ht.html');

    chdir $src_dir;
    my $ext = $^O eq 'MSWin32' ? 'bat' : 'sh';
    my $cmd = sprintf(q{_run_tex.%s -x %s},$ext, $mkr->{tex_exe});

    my $tex4ht = $bld->{tex4ht};

    my $run_tex = eval {
        require Plg::Projs::Scripts::RunTex;
        my %n = (
            skip_init => 1,
            proj    => $do_htlatex ? 'jnd_ht' : 'jnd',
            root    => getcwd(),
            tex_exe => $mkr->{tex_exe},

            obj_bld => $bld,
            obj_mkr => $mkr,

            tex4ht  => $tex4ht,
        );
        Plg::Projs::Scripts::RunTex
            ->new(%n)
            ->init_mkx;
    };

    $mkr->{ok} ||= 1;
    if ($run_tex) {
       $run_tex->run->run_after;
       $mkr->{ok} &&= $run_tex->{ok};
    }else{
       my $code = system($cmd);
       $mkr->{ok} &&= $code ? 0 : 1;
    }
    unless($mkr->{ok}){
        warn '[MAKER] fail' . "\n";
        chdir $mkr->{root};
        return $mkr;
    }

    my @dest;
    push @dest,
        $do_htlatex ? (
           catfile($mkr->{out_dir_html},$target)
        ) : (
           $mkr->{out_dir_pdf}
        )
        ;

    $DB::single = 1;
    if ($do_htlatex) {
        if (-e $ht_file) {
           foreach my $dst (@dest) {
              mkpath $dst unless -d $dst;

              my @dst_ht_files = File::Find::Rule
                 ->new->name('*.html', '*.css')->in($dst);
              map { rmtree($_) } @dst_ht_files;

              my $dst_img_dir = catfile($dst,qw(imgs));
              unless(-d $dst_img_dir){
                 mkpath $dst_img_dir;
              }else{
                 my @imgs_dst = File::Find::Rule->new
                    ->name('*.png', '*.jpg', '*.jpeg')
                    ->in($dst_img_dir);
                 map { rmtree($_) } @imgs_dst;
              }

              my @ht_files = File::Find::Rule
                 ->new->name('*.html', '*.css')->in($src_dir);
              map { move($_, $dst) } @ht_files;
              if ($do_box && $img_dir && -d $img_dir) {
                 my @imgs = File::Find::Rule
                    ->new->name('*.png', '*.jpg', '*.jpeg')
                    ->in($img_dir);

                 map { copy($_, $dst_img_dir) } @imgs;
              }
           }
        }
    }else{
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
    }

    chdir $mkr->{root};

    return $mkr;

}



1;


