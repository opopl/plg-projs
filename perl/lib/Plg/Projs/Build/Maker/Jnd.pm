
package Plg::Projs::Build::Maker::Jnd;

use strict;
use warnings;

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Capture::Tiny qw(
    capture_merged
);
use File::stat;
use File::Path qw( mkpath rmtree );
use File::Copy qw( copy );
use Data::Dumper qw(Dumper);

###jnd_compose
sub cmd_jnd_compose {
    my ($mkr) = @_;

    $mkr
        ->cmd_join
        ->copy_to_src
        ->create_bat_in_src
        ;

    my $root = $mkr->{root};
    my $proj = $mkr->{proj};

    my $jfile  = $mkr->_file_joined;
    my @jlines = read_file $jfile;

    my @nlines;
###_cnv_vars
    my ($is_img, $is_cmt);

    my (@tags);
    my $tags_projs = [ qw(projs), $mkr->{root_id}, $mkr->{proj} ];

###_cnv_loop
    foreach(@jlines) {
        chomp;

###cnv_ifcmt
        m/^\s*\\ifcmt/ && do { 
            $is_cmt = 1;
            next;
        };

###cnv_fi
        m/^\s*\\fi/ && do { 
            if ($is_cmt) { $is_cmt = 0; next; }
        };

        unless($is_cmt){
            push @nlines, $_;
            next;
        }

###cnv_img_begin
        m/^\s*img_begin/ && do { 
            $is_img = 1; next;
        };

###cnv_img_end
        m/^\s*img_end/ && do { 
            $is_img = 0; 

            @tags = ();
            
            next;
        };

###cnv_tags
        m/^\s*tags\s+(.*)/ && do { 
            next unless $is_img;

            my $tags = $1;
            $tags =~ s/\s+//g;

            push @tags, [ split("," => $tags) ];

            next;
        };

    }

    unshift @nlines,
        ' ',
        sprintf(q{\def\imgroot{%s}}, $mkr->{img_root_unix} ),
        ' '
        ;

    write_file($jfile,join("\n",@nlines) . "\n");

    return $mkr;
}

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

    mkpath $mkr->{src_dir} if -d $mkr->{src_dir};

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
 

