
if (0) {
    my $vim =<< 'eof';

TgUpdate perl_inc_plg_projs

eof
}

package Plg::Projs::Build::Maker;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Path qw( mkpath rmtree );
use File::Basename qw(basename dirname);
use File::Copy qw( copy );
use File::Slurp::Unicode;

use File::stat;
use Cwd;

use FindBin qw($Bin $Script);
use File::Find qw(find);

use Plg::Projs::Piwigo::SQL;

use base qw(
    Plg::Projs::Build::Maker::IndFile
    Plg::Projs::Build::Maker::Bat
);

use Base::Arg qw(hash_update);

use utf8; 
use Encode;
#use open qw(:utf8 :std);
binmode STDOUT, ":utf8";

use File::Dat::Utils qw(readarr);
use Capture::Tiny qw(
    capture_merged
);

use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);
use Base::DB qw(
    dbh_insert_hash
    dbh_select
    dbh_select_first
    dbh_select_as_list
    dbh_select_fetchone
    dbh_do
    dbh_list_tables
    dbh_selectall_arrayref
    dbh_sth_exec
    dbh_update_hash
    dbi_connect
);


#use open IO => ":raw:utf8"; 
#docstore.mik.ua/orelly/perl4/cook/ch08_20.htm

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

      
sub get_opt {
    my ($self) = @_;

    return $self if $self->{skip_get_opt};

    my (%opt, @optstr, $cmdline);
    
    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));
    
    @optstr = ( 
        "cmd|c=s",
    );

    $self->{root}    ||= getcwd();
    $self->{root_id} = basename($self->{root});

    unless( @ARGV ){ 
        $self->dhelp;
        exit 0;
    }else{
        $self->{proj}    = shift @ARGV;

        $cmdline = join(' ',@ARGV);
        GetOptions(\%opt,@optstr);
        $self->{opt} = {%opt};
    }

    foreach my $x (qw(cmd)) {
        $self->{$x} = $self->{opt}->{$x};
    }

    return $self;    
}

sub dhelp {
    my ($self) = @_;

    my $s = qq{

    ROOT:
        $self->{root}
    ROOT_ID:
        $self->{root_id}
    USAGE
        $Script PROJ OPTIONS
    OPTIONS
        --cmd -c CMD 

    EXAMPLES
        perl $Script aa 
        perl $Script aa -c copy_to_builds
    };

    print $s . "\n";

    return $self;    
}

sub init {
    my ($self) = @_;

    $self->get_opt;

    my $tex_opts_a = [];

    my $proj    = $self->{proj};

    my $root    = $self->{root} || '';
    my $root_id = $self->{root_id} || '';

    my $pdfout = $ENV{PDFOUT};

    my @build_dir_a = ( "builds", $proj, "b_pdflatex" );

    my $pwg = Plg::Projs::Piwigo::SQL->new;

    my $h = {
        proj            => $proj,
        pdfout          => $pdfout,
        tex_exe         => 'pdflatex',
        build_dir_unix  => join("/",@build_dir_a),
        build_dir       => catfile($root, @build_dir_a),
        bib_file        => catfile($root, qq{$proj.refs.bib}),
        out_dir_pdf     => catfile($pdfout, $root_id),
        out_dir_pdf_pwg => catfile($pdfout, $root_id, qw(pwg) ),
        dbfile          => catfile($root,'projs.sqlite'),
        pwg             => $pwg,
        cmd             => 'bare',
    };

    push @$tex_opts_a, 
        '-file-line-error',
        '-interaction nonstopmode',
        sprintf(qq{ -output-directory=./%s}, $h->{build_dir_unix}),
        ;

    my $tex_opts = join(" ", @$tex_opts_a);

    $h = { %$h,
        img_root_unix => $pwg->{img_root_unix},
        img_root      => $pwg->{img_root},
        src_dir       => catfile($h->{build_dir},qw( .. src)),
        tex_opts      => $tex_opts,
        tex_opts_a    => $tex_opts_a,
        out_dir_pdf_b => catfile($h->{out_dir_pdf}, qw(b_pdflatex) )
    };

    hash_update($self, $h, { keep_already_defined => 1 });

    return $self;
}



sub _file_joined {
    my ($self) = @_;

    my $jfile = catfile($self->{src_dir},'jnd.tex');

    return $jfile;
}

sub _file_sec {
    my ($self, $sec, $ref) = @_;

    $ref ||= {};
    my $proj = $ref->{proj} || $self->{proj};

    my $s = {
        '_main_' => sub { 
            catfile(
                $self->{root},
                join("." => ( $proj, 'tex' )) 
            ) 
        },
        '_bib_' => sub { 
            catfile(
                $self->{root},
                join("." => ( $proj, 'refs.bib' )) 
            ) 
        },
    };

    my $ss = $s->{$sec} || sub { 
            catfile(
                $self->{root},
                join("." => ( $proj, $sec, 'tex' )) 
            );
    };
    my $f = $ss->();

    return $f;
}

sub _file_ii_exclude {
    my ($self) = @_;
            
    catfile(
      $self->{root},
      join("." => ( $self->{proj}, 'ii_exclude.i.dat' )) 
    );

}

sub _file_ii_include {
    my ($self) = @_;
            
    catfile(
      $self->{root},
      join("." => ( $self->{proj}, 'ii_include.i.dat' )) 
    );

}

sub _ii_exclude {
    my ($self) = @_;

    my (@exclude);
    my $f_in = $self->_file_ii_exclude;

    my @base = $self->_ii_base;

    return @exclude;
}

sub _ii_base {
    my ($self) = @_;

    my @base_preamble;
    push @base_preamble,
        map { sprintf('preamble.%s',$_) } 
        qw(index packages acrobat_menu filecontents );

    my @base;
    push @base,
        qw(body preamble index bib),
        @base_preamble,
        qw(titlepage),
        qw(listfigs listtabs),
        qw(tabcont),
        ;
    return @base;
}

sub _ii_include {
    my ($self) = @_;

    my (@include);
    my $f_in = $self->_file_ii_include;

    my @base = $self->_ii_base;

    my $s = $self->{sections} || {};
    my @i = @{ $s->{include} || [] };
    push @include, @i;

    if (-e $f_in) {
        my @i = readarr($f_in);

        for(@i){
            /^_all_$/ && do {
                $self->{ii_include_all} = 1;
                next;
            };

            /^_base_$/ && do {
                push @include, @base;
                next;
            };

            push @include, $_;
        }
    }else{
        $self->{ii_include_all} = 1;
    }
    return @include;
}

sub _debug_sec {
    my ($self, $root_id, $proj, $sec) = @_;

            my $s =<< 'EOF'; 
\vspace{0.5cm}
{\ifDEBUG\small\LaTeX~section: \verb|_sec_| project: \verb|_proj_| rootid: \verb|_rootid_|\fi}
\vspace{0.5cm}
EOF
    $s =~ s/_sec_/$sec/g;
    $s =~ s/_proj_/$proj/g;
    $s =~ s/_rootid_/$root_id/g;

    return $s;
}

sub _join_lines {
    my ($self, $sec, $ref) = @_;

    $ref ||= {};

    $sec = '_main_' unless defined $sec;

    my $proj = $ref->{proj} || $self->{proj};
    my $file = $ref->{file} || '';

    my $root_id = $self->{root_id} || '';

    my @include = $self->_ii_include;

    my @exclude = $self->_ii_exclude;
    
    my $ii_include_all = $ref->{ii_include_all} || $self->{ii_include_all};

    my $jl = $self->{join_lines} || {};
    my $include_below = $ref->{include_below} || $jl->{include_below} || [];

    my $ss        = $self->{sections} || {};

    my $ss_insert = $ss->{insert} || {};
    my $line_sub = $ss->{line_sub} || sub { shift };

    my @ins_order = qw( hyperlinks titletoc );

    my $root = $self->{root};

    chdir $root;

    my $jfile = $self->_file_joined;
    mkpath $self->{src_dir};

    my $f = $ref->{file} || $self->_file_sec($sec,{ proj => $proj });

    if (!-e $f){ return (); }

    my @lines;
    my @flines = read_file $f;

    my $pats = {
         'ii'    => '^\s*\\\\ii\{(.+)\}.*$',
         'iifig' => '^\s*\\\\iifig\{(.+)\}.*$',
         'input' => '^\s*\\\\input\{(\S+)\}.*$',
         'sect'  => '^\s*\\\\(part|chapter|section|subsection|subsubsection|paragraph)\{.*\}\s*$',
    };

    my $delim = '%' x 50;  


    my $r_sec = {
        proj      => $proj,
        sec       => $sec,
        file      => $file,
    };
 
    my $sect;
    my @at_end;
    foreach(@flines) {
        chomp;

        $_ = $line_sub->($_, $r_sec);

###pat_sect
        m/$pats->{sect}/ && do {
            $sect = $1;
            
            my $r = {
                sect      => $sect,
            };

            push @lines, 
                $_,
                $self->_debug_sec($root_id, $proj, $sec)
                ;

            foreach my $ord (@ins_order) {
                my $ss    = $ss_insert->{$ord} || [];

                foreach my $sss (@$ss) {
                    my $scts      = $sss->{scts} || [];
                    my $sss_lines = $sss->{lines} || [];
    
                    my $ins = 0;
                    if (@$scts) {
                        $ins = (@$scts && grep { /^$sect$/ } @$scts) ? 1 : 0;
                    }
        
                    if ($ins) {
                        my @a = (ref $sss_lines eq 'ARRAY') ? @$sss_lines : $sss_lines->($r);
                        push @lines, @a;

                        if ($ord eq 'titletoc') {
                            push @at_end, @{ $sss->{lines_stop} || [] };
                        }
                    }
    
                }

            }

            next;
        };

###pat_input
        m/$pats->{input}/ && do {
            my $fname   = $1;

            my @files;
            push @files,
                $fname, qq{$fname.tex};

            while (@files) {
                my $file = shift @files;

                next unless -e $file;

                my ($proj) = ($file =~ m/^(\w+)\./);

                my @ii_lines = $self->_join_lines('',{ 
                    proj           => $proj,
                    file           => $file,
                    ii_include_all => 1,
                    include_below  => $include_below,
                });

                push @lines, 
                    $delim, '%% ' . $_, $delim,
                    @ii_lines
                    ;

            }

            next;
        };

###pat_ii
        m/$pats->{ii}/ && do {
            my $ii_sec   = $1;

            #if ($sect) {
                #print qq{ sect: $sect, ii_sec: $ii_sec }. "\n";
                #print Dumper($include_below) . "\n";
            #}

            my $iall = $ii_include_all;
            if ($sect) {
                $iall = ( grep { /^$sect$/ } @$include_below ) ? 1 : $iall;
            }

            my $inc = $iall || ( !$iall && grep { /^$ii_sec$/ } @include )
                ? 1 : 0;

            next unless $inc;

            my @ii_lines = $self->_join_lines($ii_sec,{ 
                proj           => $proj,
                ii_include_all => $iall,
                include_below  => $include_below,
            });

            push @lines, 
                $delim,
                '%% ' . $_,
                $delim,
                @ii_lines
            ;
            next;
        };

###pat_iifig
        m/$pats->{iifig}/ && do {
            my $fig_sec   = 'fig.' . $1;
            my @fig_lines = $self->_join_lines($fig_sec,{ proj => $proj });

            push @lines, 
                $delim,
                '%% ' . $_,
                $delim,
                @fig_lines
            ;

            next;
        };

        push @lines, $_;
    }
    push @lines, @at_end;

    if ($sec eq '_main_') {
        write_file($jfile,join("\n",@lines) . "\n");
    }

    return @lines;
}

sub _find_ {
    my ($self, $dirs, $exts) = @_;

    my @files;
    find({ 
            wanted => sub { 
                foreach my $ext (@$exts) {
                    if (/\.$ext$/) {
                        push @files,$File::Find::name;
                    }
                }
            } 
    },@$dirs
    );

    return @files;
}

sub _cmd_bibtex {
    my ($self, $ref) = @_;

    my $proj    = $self->{proj};

    my $cmd = sprintf('bibtex %s',$proj);

    return $cmd;
}

sub _cmd_tex {
    my ($self, $ref) = @_;

    my $opts = [
        '-interaction=nonstopmode',
        '-file-line-error',
    ];

    my $proj    = $self->{proj};

    my $cmd     = sprintf('%s %s %s',$self->{tex_exe},join(" ",@$opts),$proj);

    return $cmd;
}

sub _cmds_texindy {
    my ($self, $ref) = @_;

    my $proj = $self->{proj};

    $ref ||= {};
    my $dir = $ref->{dir} || '';

    my @files_idx = $self->_find_([$dir],[qw(idx)]);

    my @cmds;
    my $langs = {
        eng => 'english',
        rus => 'russian',
    };

    foreach my $f (@files_idx) {
        my $idx = basename($f);

        local $_ = $idx;

        my ($f) = (m/^(\w+)\./);
        my $xdy = qq{$f.xdy};

        my $M_xdy = ( -e $xdy ) ? qq{ -M $xdy } : '';
        my ($cmd_idx, $cmd_ind);
        
        $cmd_idx = sprintf(qq{texindy $M_xdy $idx });
        $cmd_ind = qq{call ind_ins_bmk $proj.ind 1 },

        m/^(.*)\.(\w+)\.idx$/ && do {
            my $core = $1;
            my $lng = $2;

            $xdy = qq{$core.$lng.xdy};
            my $lang = $langs->{$lng};

            $M_xdy = ( -e $xdy ) ? qq{ -M $xdy } : '';
            $M_xdy ||= ( -e "index.$lng.xdy" ) ? qq{ -M index.$lng.xdy } : '';

            my $enc = ( $lng eq 'rus' ) ? '-C utf8' : '';

            $cmd_idx = sprintf(qq{texindy $enc -L $lang $M_xdy $idx });
            $cmd_ind = qq{call ind_ins_bmk $core.$lng.ind 1 };
        };

        push @cmds, 
            $cmd_idx, 
            $cmd_ind
            ;
    }


    return @cmds;
}

sub _files_pdf_pwg {
    my ($self) = @_;

    my $proj    = $self->{proj};
    my $src_dir = $self->{src_dir};

    my @pdf_files;
    push @pdf_files,
        catfile($src_dir,$proj . 'jnd.pdf'),
        catfile($self->{out_dir_pdf_pwg},$proj . '.pdf'),
        ;

    return @pdf_files;

}

=head3 cmd_build_pwg

=head4 Calls 

cmd_insert_pwg

=cut

sub cmd_build_pwg {
    my ($self) = @_;

    my $proj    = $self->{proj};
    my $src_dir = $self->{src_dir};

    mkpath $self->{src_dir} if -d $self->{src_dir};
    mkpath $self->{out_dir_pdf_pwg};

    $self->cmd_insert_pwg;

    my @pdf_files = $self->_files_pdf_pwg;

    foreach my $f (@pdf_files) {
        rmtree $f if -e $f;
    }

    my $pdf_file = catfile($src_dir,'jnd.pdf');

    chdir $src_dir;
    my $ext = $^O eq 'MSWin32' ? 'bat' : 'sh';
    my $cmd = sprintf(q{_run_tex.%s -x %s},$ext, $self->{tex_exe});
    system($cmd);

    my @dest;
    push @dest, 
        $self->{out_dir_pdf_pwg},
        $self->{out_dir_pdf}
        ;

    if (-e $pdf_file) {
        foreach(@dest) {
            mkpath $_ unless -d;

            my $d = catfile($_, $proj . '.pdf');

            print "Copied PDF File to:" . "\n";
            print "     " . $d . "\n";

            copy($pdf_file, $d);
        }
    }
    chdir $self->{root};

    return $self;

}

sub cmd_insert_pwg {
    my ($self) = @_;

    $self
        ->cmd_join
        ->copy_to_src
        ->create_bat_in_src
        ;

    my $root = $self->{root};
    my $proj = $self->{proj};

    my $jfile  = $self->_file_joined;
    my @jlines = read_file $jfile;

    my @nlines;
###_cnv_vars
    my ($width, $width_local, $width_default);
    my (@opts_ig);
   
    $width = $width_default = 0.5;

    my ($is_img, $is_fig, $is_cmt, $is_tex, $is_perl);

    my (@tags, %fig, %opts);
    my $tags_projs = [ qw(projs), $self->{root_id}, $self->{proj} ];

    my (@perl_code, @perl_use);

    push @perl_use,
        q{ use Plg::Projs::Piwigo::SQL; },
        q{ use Plg::Projs::Build::Maker; },
    ;

###_cnv_loop
    foreach(@jlines) {
        chomp;

        m/^\s*\\ifcmt/ && do { 
            $is_cmt = 1;
            next;
        };

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

###cnv_width
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

###pwg_run
            my $pwg = Plg::Projs::Piwigo::SQL->new;
            local @ARGV = qw( -c img_by_tags );
            push @ARGV, 
                qw( -t ), join("," => @tags_all);

            #print Dumper(\@tags_all) . "\n";

            $pwg->run;
            my @img = @{$pwg->{img} || []};
            #print Dumper(\@img) . "\n";
            if (@img == 1) {
                my $i = shift @img;
                my $ipath = $i->{rel_path};
                my $icapt = $i->{comment} || '';
                $icapt =~ s/\r\n/\n/g;

                my $width_s = ( $width =~ /^[\d\.]+$/ ) ? "$width\\textwidth" : $width;
                unless (@opts_ig){
                    push @opts_ig, sprintf(q{width=%s},$width_s);
                }
                my $opts_ig_s = join(",",@opts_ig);

                push @nlines,
                    sprintf('\def\pic{%s/%s}', '\imgroot', $ipath),
                    sprintf('\\includegraphics[%s]{\pic}', $opts_ig_s),
                    ;


                if ($is_fig) {
                    if ($icapt) {
                        push @nlines, sprintf('\\caption{%s}',$icapt);
                    }
                }
            }else{
            }

            @opts_ig = ();
            @tags = ();
            @tags_all = ();
            %opts = ();
            $width_local = undef;
            
            next;
        };


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
        sprintf(q{\def\imgroot{%s}}, $self->{img_root_unix} ),
        ' '
        ;

    write_file($jfile,join("\n",@nlines) . "\n");

    return $self;
}

sub cmd_join {
    my ($self) = @_;

    $self->_join_lines;

    return $self;
}

sub create_bat_in_src {
    my ($self) = @_;

    my $dir  = $self->{src_dir};

    my $proj    = $self->{proj};
    my $root_id = $self->{root_id};

    my %f = (
        'latexmkrc' => sub { 
            my @cmds;
            push @cmds, 
                    ' ',
                    q{$makeindex = "mkind jnd";},
                    ' ',
                    q{$pdf_mode = 1;},
                    ' '
                    ;

            return [@cmds];
        },
    );

    my %f_bat = (
        '_clean' => sub { 
            [
                'rm *.xdy',
                'rm *.ind',
                'rm *.idx',
                'rm *.mtc*',
                'rm *.maf*',
                'rm *.ptc*',
                'latexmk -C'
            ];
        },
        '_latexmk_pdf' => sub { 
            my @cmds;
            push @cmds, 
                    ' ',
                    sprintf('latexmk -pdf jnd'),
                    ' '
                    ;

            return [@cmds];
        },
        '_mkind' => sub { 
            my @cmds;
            push @cmds, 
                    ' ',
                    q{mkind jnd},
                    ' '
                    ;

            return [@cmds];
        },
        '_view' => sub { 
            [
                sprintf('call jnd.pdf')
            ];
        },
        '_xelatex' => sub { 
            my @cmds;
            push @cmds, 
                ' ',
                #sprintf('call _clean.bat'),
                ' ',
                sprintf('set opts='),
                sprintf('set opts=%%opts%% -file-line-error'),
                ' ',
                sprintf('xelatex %%opts%% jnd'),
                sprintf('xelatex %%opts%% jnd'),
                ' ',
                ;
            return [@cmds];
        },
        '_pdflatex' => sub { 
            my @cmds;
            push @cmds, 
                ' ',
                #sprintf('call _clean.bat'),
                ' ',
                sprintf('set opts='),
                sprintf('set opts=%%opts%% -file-line-error'),
                ' ',
                sprintf('pdflatex %%opts%% jnd'),
                sprintf('pdflatex %%opts%% jnd'),
                ' ',
                ;
            return [@cmds];
        },
        '_run_tex' => sub { 
            my @cmds;
            push @cmds, 
                sprintf('call %s',$self->_bat_file('_clean')),
                sprintf('%s jnd %%*',$self->_bat_file('run_tex')),
                ;
            return [@cmds];
        },
    );

    while( my($f,$l) = each %f_bat ){
        my $fl = $self->_bat_file($f);

        my $bat_path = catfile($dir,$fl);
        my $lines = $l->();

        write_file($bat_path,join("\n",@$lines) . "\n");
    }

    return $self;
}

sub copy_to_src {
    my ($self) = @_;

    mkpath $self->{src_dir};

    $self
        ->copy_bib_to_src
        ->copy_sty_to_src
        ;

    return $self;
}

sub copy_bib_to_src {
    my ($self) = @_;

    my $root = $self->{root};

    my @bib; 
    push @bib, 
        $self->_file_sec('_bib_');


    foreach(@bib) {
        my $bib_src     = $_;
        my $bib_dest    = catfile($self->{src_dir},basename($_));

        copy($bib_src, $bib_dest);
    }

    return $self;
}

sub copy_sty_to_src {
    my ($self) = @_;

    my $root = $self->{root};

    my @sty; 
    push @sty, 
        qw(projs.sty);

    mkpath $self->{src_dir};

    foreach(@sty) {
        my $sty_src     = catfile($root,$_);
        my $sty_dest    = catfile($self->{src_dir},$_);

        copy($sty_src, $sty_dest);
    }

    return $self;
}

sub cmd_copy_to_builds {
    my ($self) = @_;

    my $proj = $self->{proj};
    my $root = $self->{root};

    my $dbfile = $self->{dbfile};

    my $dbh = dbi_connect({
        dbfile => $self->{dbfile},
    });

    my $ref = {
        dbh     => $dbh,
        t       => 'projs',
        f       => [qw(file)],
        p       => [$proj],
        cond    => qq{ WHERE proj = ? },
    };
    $self->{files} = dbh_select_as_list($ref);
    mkpath $self->{src_dir};

    foreach my $file (@{ $self->{files} || [] }) {
        my $path = catfile($root,$file);
        copy($path, $self->{src_dir} );
    }

    return $self;
}

sub run_cmd {
    my ($self, $ref) = @_;

    $ref ||= {};
    my $cmd = $ref->{cmd} || $self->{cmd};

    if ($cmd) {
        my $sub = 'cmd_'.$cmd;
        if ($self->can($sub)) {
            $self->$sub;
        }else{
            warn "No command defined: " . $cmd . "\n";
            exit 1;
        }
        exit 0;
    }

    return $self;
}

sub run {
    my ($self) = @_;

    $self->run_cmd;
    
    return $self;
}

sub cmd_bare {
    my ($self) = @_;

    mkpath $self->{build_dir};

    my $proj = $self->{proj};
    my $root = $self->{root};

    my @dirids = qw( 
        out_dir 
        out_dir_pdf 
        out_dir_pdf_b 
        out_dir_pdf_pwg
    );

    foreach my $dirid (@dirids) {
        my $dir = $self->{$dirid};
        mkpath $dir;
    }

    my $proj_bib = catfile( $self->{out_dir}, "$proj.bib" );
    copy( $self->{bib_file}, $proj_bib ) 
        if -e $self->{bib_file};
    
    my $cmd_tex = join(" ", @$self{qw( tex_exe tex_opts )}, $proj );
    system($cmd_tex);

    chdir $self->{build_dir};
    
    system(qq{ bibtex $proj } ) if -e $proj_bib;

    my $idx = "$proj.idx";
    if (-e $idx) {
        system(qq{ texindy -L russian -C utf8 $idx });
    }

    my $ind_file = catfile("$proj.ind");
    #$self->ind_ins_bmk($ind_file,1);

    #return ;
    chdir $self->{root};

    system($cmd_tex);
    system($cmd_tex);

    my $built_pdf = catfile($self->{build_dir}, "$proj.pdf");

    if (! -e $built_pdf) {
        warn 'NO PDF FILE!' . "\n";
        return;
    }

    my @pdf_files;
    push @pdf_files, 
        catfile($self->{out_dir_pdf_b},"$proj.pdf"),
        catfile($self->{out_dir_pdf},"$proj.pdf"),
        ;

    foreach my $dest (@pdf_files) {
        copy($built_pdf, $dest);

        if (-e $dest) {
            print "Copied generated PDF to: " . "\n";
            print "     $dest" . "\n";
        }
    }

    return $self;

}

1;
