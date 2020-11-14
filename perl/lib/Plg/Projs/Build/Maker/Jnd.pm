
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
    my ($is_img, $is_cmt);
    my ($is_tab, $tab, $i_col);

    my @keys = qw(url caption tags name);
    my ($url, $caption);
    my ($d, @data, @fig);
    $d = {};

    my @fig_start = ( q|\begin{figure}[ht] |, q|  \centering | );
    my @fig_end = ( q|\end{figure}| );

    my @tab_end = ( q|  \end{tabular}|  );

    my ($img_width, $img_width_default);
    $img_width_default = 0.7;

    my $push_d = sub { push @data, $d if keys %$d; };
    my $push_d_reset = sub { $push_d->(); $d = {}; };
    my $tex_caption = sub { 
		$caption ? ( sprintf(q| \caption{%s} |, $caption ) ) : ();
    };

    my $lnum = 0;
    #return $mkr;
###loop_LINES
    LINES: foreach(@jlines) {
        $lnum++; chomp;

        m/^\s*\\ifcmt/ && do { $is_cmt = 1; next; };
###m_\fi
        m/^\s*\\fi/ && do { 
            unless($is_cmt){
                push @nlines, $_; next;
            }

            if ($is_img) {
                $is_img = 0;
                $push_d_reset->();
            }

            $is_cmt = 0 if $is_cmt; 

            next unless @data;

###if_tab_push_fig
            if ($tab) {
                $i_col = 1;

                $tab->{cols} ||= 2;
                $tab->{align} ||= 'c';
                push @fig, 
                    @fig_start,
                    sprintf(q| \begin{tabular}{*{%s}{%s}} |,@{$tab}{qw(cols align)}),
                    ;
            }

            #print join(" ", $lnum,  scalar @data ) . "\n";

            while(@data){
                $d = shift @data;

                my ($tags, $name);
                ($url, $caption, $tags, $name) = @{$d}{@keys};

                texify(\$caption) if $caption;
    
                my $w = {};
                for(qw( url name )){
                    $w->{$_}  = $d->{$_} if $d->{$_};
                }

                my ($rows, $cols, $q, $p) = dbh_select({
                    dbh => $mkr->{dbh_img},
                    q   => q{ SELECT img, caption, url FROM imgs },
                    p   => [],
                    w   => $w,
                });

                $img_width = $d->{width} || $img_width_default;

                if (@$rows == 1) {
                    my $rw = shift @$rows;
                    my $o = sprintf(q{ width=%s\textwidth },$img_width);
    
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

                    unless ($tab) {
                        push @fig,@fig_start; 
                    }
    
                    push @fig, 
                        sprintf(q|  \includegraphics[%s]{%s} |, $o, $img_path ),
                        ;
###if_tab_col
                    if ($tab) {
                        my $s;
                        if ( $i_col == $tab->{cols} ) {
                            $i_col = 1;
                            $s = q{\\\\};
                        }else{
                            $s = q{&};
                            $i_col++;
                        }
                        push @fig, $s;
                    }else{
                        push @fig, 
                            $tex_caption->(), @fig_end;
                    }
                }
            }
###end_loop_@data

            if($tab){
                push @fig, 
                    @tab_end, $tex_caption->(),
                    @fig_end ;
            }

            push @nlines, @fig;

            @fig = ();
            $d = {};
            $caption = '';
            $tab = undef;

            next; 
        };
###end_m_\fi

        unless($is_cmt){ push @nlines, $_; next; }

###m_tab_begin
        m/^\s*tab_begin\b(.*)$/g && do { 
            $is_tab = 1; 
            my $opts_s = $1;
            next unless $opts_s;

            $tab={};

            my @tab_opts = grep { length } map { defined ? trim($_) : () } split("," => $opts_s);
            for(@tab_opts){
                my ($k, $v) = (/([^=]+)=([^=]+)/g);
                $tab->{$k} = $v;
            }
            #print Dumper($tab) . "\n";
            next; 
        };

        m/^\s*img_begin\b/g && do { $is_img = 1; next; };

###m_tab_end
        m/^\s*tab_end\b/g && do { 
            $is_tab = 0; 

            $push_d_reset->();
            next; 
        };

###m_img_end
        m/^\s*img_end\b/g && do { 
            $is_img = 0 if $is_img; 

            $push_d_reset->();
            next; 
        };

        while(1){
###m_pic
            m/^\s*(pic|doc)\s+(.*)$/g && do { 
                $push_d_reset->();

                $is_img = 1;

                $url = $2;
                $d = { url => $url };
                if ($1 eq 'doc') {
                    $d->{type} = 'doc';
                }
                last; 
            };

###if_is_img
            if ($is_img) {
###m_url
                m/^\s*url\s+(.*)$/g && do { 
                    $push_d_reset->();

                    $d = { url => $1 };
                    $url = $1;
                    last;
                };

                m/^\s*(\w+)\s+(.*)$/g && do { 
                   my $k = $1;
                   #next unless grep { /^$k$/ } qw( caption name tags );

                   $d->{$1} = $2; 
                };

                last;
            }

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
 

