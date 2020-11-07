
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
    my ($width, $width_local, $width_default);
    my (@opts_ig);
   
    $width = $width_default = 0.5;

    my ($is_img, $is_fig, $is_cmt, $is_tex, $is_perl);

    my (@tags, %fig, %opts);
    my $tags_projs = [ qw(projs), $mkr->{root_id}, $mkr->{proj} ];

    my (@perl_code, @perl_use);

    push @perl_use,
        q{ use Plg::Projs::Build::Maker; },
    ;

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
            if ($is_cmt) {
                $is_cmt = 0;
                next;
            }
        };

        unless($is_cmt || $is_tex){
            push @nlines, $_;
            next;
        }

###cnv_opts
        m/^\s*opts\s+(.*)$/ && do { 
            my $opts = $1;
            %opts = map { $_ => 1 } split("," => $opts);
            next;
        };

###cnv_width_fig
        m/^\s*width_fig\s+(.*)/ && do { 
            next unless $is_fig;

            $fig{width} = $1; 

            next;
        };
###cnv_perl_begin
        m/^\s*perl_begin\s*$/ && do { $is_perl = 1; next; };

###cnv_perl_file
        m/^\s*perl_file\s+(\S+)\s*$/ && do { 
            my $fname = $1;
            my $perl_file = catfile($root,join("." => ($proj,$fname,'pl') ) );

            my @out = `perl $perl_file`;
            push @nlines, 
                '%perlout_start ' . $fname,
                @out,
                '%perlout_end',
                ;
            next;
        };

###cnv_perl_end
        m/^\s*perl_end\s*$/ && do { 
            $is_perl = 0;

            unshift @perl_code, @perl_use;

            my $code = join("\n",@perl_code);
            
            my ($merged,$res) = capture_merged { eval qq{$code}; };

            my @tex;
            push @tex,
                '%perleval_start',
                '%res ' . $res,
                ( split("\n" => $merged) ),
                '%perleval_end',
                ;  

            push @nlines, map { s/^/%/g; $_ } @tex;

            @perl_code = ();
            next; 
        };

        if ($is_perl) {
            push @perl_code, $_;
        }

###cnv_opts_ig
        m/^\s*opts_ig\s+(.*)$/ && do { 
            next unless $is_img;

            push @opts_ig, $1; next;
        };

###cnv_img_width
        m/^\s*width\s+(.*)/ && do { 
            next unless $is_img;

            $width_local = $1; next;
        };

###cnv_tags_fig
        m/^\s*tags_fig\s+(.*)/ && do { 
            next unless $is_fig;

            my @tf = @{$fig{tags} || []};
            push @tf, split "," => $1;
            $fig{tags} = [@tf]; 

            next;
        };

###cnv_fig_begin
        m/^\s*fig_begin/ && do { 
            $is_fig = 1; 

            push @nlines,
                q{ \\begin{figure}[ht] };

            next;
        };

###cnv_fig_end
        m/^\s*fig_end/ && do { 
            $is_fig = 0; 

            push @nlines,
                q{ \\end{figure} };

            %fig = ();
            
            next;
        };
###cnv_tex_begin
        m/^\s*tex_begin\s*$/ && do { $is_tex = 1; next; };
        m/^\s*tex_end\s*$/ && do { $is_tex = 0; next; };

###cnv_tex
        m/^\s*tex\s+(.*)$/ && do {  
            push @nlines, $1; next; 
        };

###cnv_img_begin
        m/^\s*img_begin/ && do { 
            $is_img = 1; next;
        };

###cnv_img_end
        m/^\s*img_end/ && do { 
            $is_img = 0; 

            $width = $width_local || $fig{width} || $width_default;

            my @tags_all;
            unless ($opts{use_any}) {
                push @tags, $tags_projs;
            }

            push @tags, $fig{tags} || [];

            my @tags_arr;
            foreach my $tline (@tags) {
                my $tt_comma = join("," => @$tline);

                push @tags_arr, @$tline;

                push @tags_all, $tt_comma;
                push @nlines, 
                    q{%tags: } . $tt_comma;
            }
            @tags_arr = sort { length($a) <=> length($b) } @tags_arr;
            my $tags_space = join(" ",@tags_arr);
            push @nlines, q{%tags_space: } . $tags_space;

###todo
            print Dumper({ tags_all => \@tags_all }) . "\n";
            #push @nlines, image tex cmds

            @opts_ig = ();
            @tags = ();
            @tags_all = ();
            %opts = ();
            $width_local = undef;
            
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
        sprintf(q{\def\pwgroot{%s}}, $mkr->{pwg_root_unix} ),
        ' '
        ;

    write_file($jfile,join("\n",@nlines) . "\n");

    return $mkr;
}

=head3 cmd_build_pwg

=head4 Calls 

cmd_insert_pwg

=cut

###jnd_build
sub cmd_jnd_build {
    my ($mkr) = @_;

    my $proj    = $mkr->{proj};
    my $src_dir = $mkr->{src_dir};

    my $proj_pdf_name = $mkr->{pdf_name} || $proj;

    mkpath $mkr->{src_dir} if -d $mkr->{src_dir};
    mkpath $mkr->{out_dir_pdf_pwg};

    $mkr->cmd_jnd_compose;

    my @pdf_files = $mkr->_files_pdf_pwg;

    foreach my $f (@pdf_files) {
        rmtree $f if -e $f;
    }

    my $pdf_file = catfile($src_dir,'jnd.pdf');

    chdir $src_dir;
    my $ext = $^O eq 'MSWin32' ? 'bat' : 'sh';
    my $cmd = sprintf(q{_run_tex.%s -x %s},$ext, $mkr->{tex_exe});
    system($cmd);

    my @dest;
    push @dest, 
        #$mkr->{out_dir_pdf_pwg},
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
 

