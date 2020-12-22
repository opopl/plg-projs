
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
    my ($is_tab, $tab, $ct);

###subs_$tab
    my $tab_val = sub { 
        my ($k) = @_;
        return unless $tab;
        $tab->{$k};
    };

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
           fig_env    => 'figure',
           row_caps   => {},
           cap_list   => [],
       };
       hash_inject($tab, $h);
    };
    my $tab_col_type = sub {
        return unless $tab;
        my ( $type ) = @_;
        $tab->{col_type} = $type if $type;
        return $tab->{col_type};
    };
    my $tab_col_type_toggle = sub {
        while(1){
            my $ct = $tab_col_type->();
            ( $ct eq 'cap') && do { $tab_col_type->('img'); last; };
            ( $ct eq 'img') && do { $tab_col_type->('cap'); last; };
            last;
        }
        return $tab_col_type->();
    };
    my $tab_num_cap = sub {
        return unless $tab;
        my $rc = $tab->{row_caps};
        return unless keys %$rc;
        my $i_col  = $tab->{i_col};
        my $rc_col = $rc->{$i_col} || {};
        my $i_cap  = $rc_col->{i_cap};
        return $i_cap;
    };
    my $tab_start = sub {
       ($tab) ? sprintf(q| \begin{%s}{*{%s}{%s}} |,@{$tab}{qw(env cols align)}) : '';
    };

    my $tex_caption_tab = sub { 
        my $c = $tab->{caption} || '';
        return unless $c;

        my @caps = map { sprintf('\textbf{(%s)} %s', @{$_}{qw(i_cap caption)}) } @{$tab->{cap_list}};
        my $c_long = join(" ", $c, @caps );

        my @c; push @c, sprintf(q| \caption[%s]{%s} |, $c, $c_long );
        return @c;
    };

###vars_author
    my ($d_author);

###vars_@data
    my ($d, @data, @fig);
    $d = {};
    my @keys = qw(url caption tags name);
    my ($img, $img_path, $url, $caption);


###vars_$img_width
    my ($img_width, $img_width_default);
    $img_width_default = 0.7;

###vars_$sec
    my ($sec);

###subs
    my ($get_width, $get_width_tex);
    my ($push_d, $push_d_reset, $set_null, $tex_caption);

    $get_width = sub {
       $d->{width} || $tab_val->('width') || $img_width_default;
    };

    $get_width_tex = sub {
        my $w = $get_width->();
        for($w){
            /^(\d+(?:|\.\d+))$/ && do {
                $w = qq{$w\\textwidth};
            };
            last;
        }
        return $w;
    };

    $push_d = sub { push @data, $d if keys %$d; };
    $push_d_reset = sub { $push_d->(); $d = {}; };

    $tex_caption = sub { 
        $caption ? ( sprintf(q| \caption{%s} |, $caption ) ) : ();
    };

    $set_null = sub {
        @fig = ();
        $d = {};
        $caption = '';
        $tab = undef;
    };

###subs_fig
    my ($fig_env, $fig_start, $fig_end, $fig_skip);

    $fig_env = sub { $tab_val->('fig_env') || $d->{fig_env} || 'figure'; };

###sub_fig_start
    $fig_start = sub { 
        return () if $fig_skip->();

        my @s;
        my $fe = $fig_env->();
        for($fe){
            /^(figure)/ && do {
                push @s,
                    q|\begin{figure}[ht] |, 
                    q|  \centering |;
                last;
            };
            /^(wrapfigure)/ && do {
                push @s, sprintf(q/\begin{%s}{R}{%s}/,$fe,$get_width_tex->() );
                last;
            };

            last;
        }

        return @s;
    };
###sub_fig_end
    $fig_end = sub {
        my @e;
        return () if $fig_skip->();

        my $fe = $fig_env->();
        push @e, sprintf(q|\end{%s}|,$fe);
        return @e;
    };

###sub_fig_skip
    $fig_skip = sub {
        my $t = $d->{type} || '';
        (grep { /^$t$/ } qw(ig)) ? 1 : 0;
    };

    my $lnum = 0;
    #return $mkr;
###loop_LINES
    LINES: foreach(@jlines) {
        $lnum++; chomp;

        m/^\s*%/ && $is_cmt && do { push @nlines,$_; next; };

###m_ii
        m/^\s*%%\s*\\ii\{(.*)\}\s*$/ && do {
            $sec = $1;
        };

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
                push @fig, $fig_start->(), $tab_start->();
            }

            #print join(" ", $lnum,  scalar @data ) . "\n";

###while_@data
            while(1){
                $ct   = $tab_col_type->();

###if_ct_img
                if (@data && (!$ct || ($ct eq 'img')) ){
                    $d = shift @data || {};
                    $img = undef;
    
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

                    unless (@$rows) {
                         my $r = {    
                             msg => q{ No image found in Database! },
                             url => $url,
                         };
                         warn Dumper($r) . "\n";
                         push @nlines, qq{%Image not found: $url };
                         next;
                    }

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
        
                            push @{$tab->{cap_list}},
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
                        $rows = [];

                        ($img) = @{$rw}{qw(img)};
        
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
    
                        push @fig,$fig_start->() unless $tab;

                        my $o = sprintf(q{ width=%s\textwidth },$img_width);
###push_includegraphics

                        push @fig, 
                            $tab ? (sprintf('%% row: %s, col: %s ', @{$tab}{qw(i_row i_col)})) : (),
                            #sprintf(q|%% %s|,$url),
                            sprintf(q|  \includegraphics[%s]{%s} |, $o, $img_path ),
                            $caption ? (sprintf(q|%% %s|,$caption)) : (),
                            ;
                    }

###end_if_ct_img
                    }elsif($ct && ($ct eq 'cap')){
                        #print join(" ",qq{$ct},@{$tab}{qw(i_col i_row)}) . "\n" if $ct;
                        my $num_cap = $tab_num_cap->();
                        push @fig, sprintf('(%s)',$num_cap) if $num_cap;

                    }else{
                        last;
                    }
###end_if_ct_cap

###if_tab_col
                    if ($tab) {
                        $caption = undef;
                        my ($s, %caps);

                        %caps = %{$tab->{row_caps}};

                        my $at_end = ( $tab->{i_col} == $tab->{cols} ) ? 1 : 0;
                        if ($at_end) {

                            $tab->{i_col} = 1;

                            $tab->{i_row}++ if $ct eq 'img';
                            $tab->{row_caps} = {} if $ct eq 'cap';

                            unless(@data){
                                last unless keys %caps;
                            }

###call_tab_col_toggle
                            # if there are any captions, switch row type to 'cap'
                            $ct = $tab_col_type_toggle->() if keys %caps;

                            $s = q{\\\\};
                        }else{
                            $s = q{&};
                            $tab->{i_col}++;
                        }
                        push @fig, $s;
                    }elsif(keys %$d){
                        #print Dumper({ '$d' => $d }) . "\n";
###push_fig_end
                        push @fig, $tex_caption->(), $fig_end->();

                    }

                unless (@data) {
                    do { last; } unless $ct;
                    do { last; } if ( $ct eq 'cap' ) && ($tab->{i_col} == $tab->{cols});
                }
                next;
            }
###end_loop_@data

            if($tab){
                push @fig, 
                    $tab_end->(), $tex_caption_tab->(),
                    $fig_end->();
            }

            push @nlines, @fig;

            $set_null->();

            next LINES; 
        };
###end_m_\fi

        unless($is_cmt){ push @nlines, $_; next; }

###m_author_begin
        m/^\s*author_begin\b(.*)$/g && do { 
            $d_author = {};
        };

###m_author_end
        m/^\s*author_end\b(.*)$/g && do { 
            my @author_ids = split("," => $d_author->{author_id} || '');
            next unless @author_ids;

            foreach my $author_id (@author_ids) {
                my $prj    = $mkr->{prj};
                my $author = $prj->_author_get({ author_id => $author_id });
    
                $author =~ s/\(/ \\textbraceleft /g;
                $author =~ s/\)/ \\textbraceright /g;
    
                push @nlines, sprintf(q{\Pauthor{%s}}, $author) if $author;
    
                $d_author = undef;

            }
            next;
        };

        if ($d_author) {
            m/^\s*(\w+)\s+(\S+)\s*$/g && do { 
                $d_author->{$1} = $2;
                next;
            };
        }

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

###m_img_begin
        m/^\s*img_begin\b/g && do { $is_img = 1; next; };

###m_tab_end
        m/^\s*tab_end\b/g && do { 
            $is_tab = 0; $is_img = 0;

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
###m_pic_doc_ig
            m/^\s*(pic|doc|ig)\s+(.*)$/g && do { 
                $push_d_reset->();

                $is_img = 1;

                $url = $2;
                $d = { url => $url };

                my $k = $1;
                $d->{type} = $k;
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

###m_other
                m/^\s*(\w+)\s+(.*)$/g && do { 
                   my $k = $1;
                   #next unless grep { /^$k$/ } qw( caption name tags );

                   $d->{$1} = $2; 
                };

                last;
            }

            last;
        }

###m_other_tab
        m/^\s*(\w+)\s+(.*)$/g && do { 
            $tab->{$1} = $2 if $tab;
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
 

