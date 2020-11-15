
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
);

###jnd_compose
sub cmd_jnd_compose {
    my ($mkr) = @_;

    $mkr
        ->cmd_json_out_runtex
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

###vars_$tab
    my ($is_tab, $tab);

###subs_$tab
    my $tab_end = sub { ($tab && $tab->{env}) ? sprintf(q| \end{%s}|,$tab->{env}) : '' };
    my $tab_defaults = sub {
       return unless $tab;
       my $h = {
           cols       => 2,
           align      => 'c',
           env        => 'tabular',
           i_col      => 1,
           i_row      => 1,
           i_cap      => 1,
           col_type   => 'img',
           row_caps   => {},
           cap_figs   => [],
       };
       hash_inject($tab, $h);
    };
    my $tab_col = sub {
        return unless $tab;
        my ( $type ) = @_;
        $tab->{col_type} = $type if $type;
        return $tab->{col_type};
    };
    my $tab_num_cap = sub {
        return unless $tab;
        my $rc = $tab->{row_caps};
        return unless keys %$rc;
        my $i_col = $tab->{i_col};
        my $i_cap = $rc->{$i_col}->{i_cap};
        return $i_cap;
    };
    my $tab_col_toggle = sub {
        while(1){
            my $tp = $tab_col->();
            ( $tp eq 'cap') && do { $tab_col->('img'); last; };
            ( $tp eq 'img') && do { $tab_col->('cap'); last; };
            last;
        }
    };

    my $tab_start = sub {
       ($tab) ? sprintf(q| \begin{%s}{*{%s}{%s}} |,@{$tab}{qw(env cols align)}) : '';
    };

###vars_@data
    my ($d, @data, @fig);
    $d = {};
    my @keys = qw(url caption tags name);
    my ($url, $caption);

    my @fig_start = ( q|\begin{figure}[ht] |, q|  \centering | );
    my @fig_end = ( q|\end{figure}| );

###vars_$img_width
    my ($img_width, $img_width_default);
    $img_width_default = 0.7;

###subs
    my $get_width = sub {
       $d->{width} || (defined $tab && $tab->{width}) || $img_width_default;
    };

    my $push_d = sub { push @data, $d if keys %$d; };
    my $push_d_reset = sub { $push_d->(); $d = {}; };

    my $tex_caption = sub { 
        $caption ? ( sprintf(q| \caption{%s} |, $caption ) ) : ();
    };
    my $tex_caption_tab = sub { 
        $tab->{caption} ? ( sprintf(q| \caption{%s} |, $tab->{caption} ) ) : ();
    };

    my $lnum = 0;
    #return $mkr;
###loop_LINES
    LINES: foreach(@jlines) {
        $lnum++; chomp;

        m/^\s*%/ && $is_cmt && do { push @nlines,$_; next; };

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

###if_tab_push_tab_start
            if ($tab) {
                $tab_defaults->();

                $tab->{width} ||= ( $img_width_default / $tab->{cols} );
                push @fig, @fig_start, $tab_start->();
            }

            #print join(" ", $lnum,  scalar @data ) . "\n";

###while_@data
            while(@data){
                $d = shift @data;

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
                next unless @$rows;

                my ($tags, $name);
                ($url, $caption, $tags, $name) = @{$d}{@keys};

                texify(\$caption) if $caption;

###if_tab_push_row_caps
                if ($tab) {
                    my $i_col = $tab->{i_col};

                    if ($caption) {
                        $tab->{row_caps}->{$i_col} = { 
                            caption => $caption,
                            i_cap   => $tab->{i_cap},
                        };
    
                        push @{$tab->{cap_figs}},
                            { 
                                i_col   => $tab->{i_col},
                                i_row   => $tab->{i_row},
                                i_cap   => $tab->{i_cap},
                                caption => $caption,
                            }
                        ;
                        $tab->{i_cap}++;
                    }
                }

                $img_width = $get_width->();

                if (@$rows == 1) {
                    my $rw = shift @$rows;
    
                    my $img = $rw->{img};
    
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
    
                    my $o = sprintf(q{ width=%s\textwidth },$img_width);
###push_includegraphics
                    while(1){
                        my $tp = $tab_col->();
                        $tp && ($tp eq 'cap') && do { 
                            my $num_cap = $tab_num_cap->();
                            push @fig, sprintf('(%s)',$num_cap) if $num_cap;
                            last; 
                        };

                        push @fig, 
                            $tab ? (sprintf('%% row: %s, col: %s ', @{$tab}{qw(i_row i_col)})) : (),
                            sprintf(q|%% %s|,$rw->{url}),
                            sprintf(q|  \includegraphics[%s]{%s} |, $o, $img_path ),
                            $caption ? (sprintf(q|%% %s|,$caption)) : (),
                            ;
                        last;
                    }
###if_tab_col
                    if ($tab) {
                        $caption = undef;
                        my ($s, $tp, %caps);

                        $tp   = $tab_col->();
                        %caps = %{$tab->{row_caps}};

                        if ( $tab->{i_col} == $tab->{cols} ) {
                            print Dumper(\%caps) . "\n";

                            $tab->{i_col} = 1;

                            $tab->{i_row}++ if $tp eq 'img';
                            $tab->{row_caps} = {} if $tp eq 'cap';

                            # if there are any captions, switch row type to 'cap'
                            $tab_col_toggle->() if keys %caps;
                            $s = q{\\\\};
                        }else{
                            $s = q{&};
                            $tab->{i_col}++;
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
                    $tab_end->(), $tex_caption_tab->(),
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
            $caption = undef;
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
 

