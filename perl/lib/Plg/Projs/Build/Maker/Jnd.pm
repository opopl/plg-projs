
package Plg::Projs::Build::Maker::Jnd;

use strict;
use warnings;

use utf8;

binmode STDOUT,':encoding(utf8)';

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Plg::Projs::Tex::Gen;
use Plg::Projs::Tex qw(
    q2quotes
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
);

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

    my @keys = qw(url caption tags);
    my %d;

###_cnv_loop
    foreach(@jlines) {
        chomp;

        m/^\s*\\ifcmt/ && do { $is_cmt = 1; next; };
        m/^\s*\\fi/ && do { 
            $is_cmt = 0 if $is_cmt; 

            my ($url, $caption, $tags) = @d{@keys};

            my $w = {};
            for(qw( url tags name )){
                $w->{$_}  = $d{$_} if $d{$_};
            }

            my ($rows, $cols, $q, $p) = dbh_select({
                dbh => $mkr->{dbh_img},
                q   => q{ SELECT img, caption, url FROM imgs },
                p   => [],
                w   => $w,
            });
            my @fig = ();
            if (@$rows == 1) {
                my $rw = shift @$rows;
                my $o = q{width=0.7\textwidth};

                my $caption = $rw->{caption} || '';
                my $img     = $rw->{img};

                my $img_path = sprintf(q{\imgroot/%s},$img);

                my $img_file = catfile($mkr->{img_root},$img);
                unless (-e $img_file) {
                    my $r = {    
                        msg => q{Image file not found!},
                        img => $img,
                        url => $url,
                    };
                    warn Dumper($r) . "\n";
                    next;
                }

                q2quotes(\$caption);

                push @fig, 
                    q| \begin{figure}[ht] |,
                    sprintf(q| \includegraphics[%s]{%s} |, $o, $img_path ),
                    $caption ? ( sprintf(q| \caption{%s} |, $caption ) ) : (),
                    q| \end{figure} |,
                    ;
            }
            push @nlines, @fig;

            #print Dumper({ fig => \@fig }) . "\n";

            @tags = ();
            %d = ();

            next; 
        };

        unless($is_cmt){ push @nlines, $_; next; }

        m/^\s*img_begin/ && do { $is_img = 1; next; };
        m/^\s*img_end/ && do { 
            $is_img = 0; 
            next;
        };

        while(1){
            if ($is_img) {
                for my $k (@keys){
                    m/^\s*$k\s+(.*)$/g && do { 
                        $d{$k} = $1; 
                        $d{$k} =~ s/\s+//g;
                    };
                }

                if ($d{tags}) {
                    push @tags, [ split("," => $d{tags} ) ];
                }
                last;
            }
    
            m/^\s*pic\s+(.*)$/g && do { 
                $d{url} = $1;
                last; 
            };

            last;
        }

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
 

