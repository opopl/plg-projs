
package Plg::Projs::Build::PdfLatex;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Path qw( mkpath rmtree );
use File::Basename qw(basename dirname);
use File::Copy qw( copy );
use File::Slurp::Unicode;

use FindBin qw($Bin $Script);
use File::Find qw(find);

use Plg::Projs::Piwigo::SQL;

use base qw(
    Plg::Projs::Build::PdfLatex::IndFile
);

use utf8; 
use Encode;
#use open qw(:utf8 :std);
binmode STDOUT, ":utf8";

use File::Dat::Utils qw(readarr);

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

    my (%opt, @optstr, $cmdline);
    
    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));
    
    @optstr = ( 
        "cmd|c=s",
    );

    $self->{root}    = $Bin;

    unless( @ARGV ){ 
        $self->dhelp;
        exit 0;
    }else{
        $self->{proj}    = shift @ARGV;
        $self->{root_id} = shift @ARGV;

        $cmdline = join(' ',@ARGV);
        GetOptions(\%opt,@optstr);
        $self->{opt} = {%opt};
    }

    return $self;    
}

sub dhelp {
    my ($self) = @_;

    my $s = qq{

    USAGE
        $Script PROJ ROOT_ID OPTIONS
    OPTIONS
        --cmd -c CMD 

    EXAMPLES
        $Script aa texdocs
        $Script aa texdocs -c copy_to_builds
    };

    print $s . "\n";

    return $self;    
}

sub init {
    my ($self) = @_;

    $self->get_opt;

    my $tex_opts_a = [];

    my $root    = $self->{root};
    my $root_id = $self->{root_id};
    my $proj    = $self->{proj};

    my $pdfout = $ENV{PDFOUT};

    my @build_dir_a = ( "builds", $proj, "b_pdflatex" );

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
    };

    push @$tex_opts_a, 
        '-file-line-error',
        '-interaction nonstopmode',
        sprintf(qq{ -output-directory=./%s}, $h->{build_dir_unix}),
        ;

    my $tex_opts = join(" ", @$tex_opts_a);

    $h = { %$h,
        src_dir       => catfile($h->{build_dir},qw( .. src)),
        tex_opts      => $tex_opts,
        tex_opts_a    => $tex_opts_a,
        out_dir_pdf_b => catfile($h->{out_dir_pdf}, qw(b_pdflatex) )
    };

    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

    return $self;
}



sub _file_joined {
    my ($self) = @_;

    my $jfile = catfile($self->{src_dir},$self->{proj} . '.tex');

    return $jfile;
}

sub _file_sec {
    my ($self, $sec) = @_;

    my $s = {
        '_main_' => sub { 
            catfile(
                $self->{root},
                join("." => ( $self->{proj}, 'tex' )) 
            ) 
        },
        '_bib_' => sub { 
            catfile(
                $self->{root},
                join("." => ( $self->{proj}, 'refs.bib' )) 
            ) 
        },
    };

    my $ss = $s->{$sec} || sub { 
            catfile(
                $self->{root},
                join("." => ( $self->{proj}, $sec, 'tex' )) 
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

sub _join_lines {
    my ($self, $sec) = @_;

    $sec ||= '_main_';

    my $proj = $self->{proj};
    chdir $self->{root};

    my @include = $self->_ii_include;
    my @exclude = $self->_ii_exclude;

    my $jfile = $self->_file_joined;
    mkpath $self->{src_dir};

    my $f = $self->_file_sec($sec);

    if (!-e $f){ return (); }

    my @lines;
    my @flines = read_file $f;

    my $pats = {
         'ii'    => '^\s*\\\\ii\{(.+)\}.*$',
         'iifig' => '^\s*\\\\iifig\{(.+)\}.*$',
         'input' => '^\s*\\\\input\{(.*)\}.*$',
    };

    my $delim = '%' x 50;  
 
    foreach(@flines) {
        chomp;

        m/$pats->{ii}/ && do {
            my $ii_sec   = $1;

            my $iall = $self->{ii_include_all};
            my $inc = $iall || ( !$iall && grep { /^$ii_sec$/ } @include )
                ? 1 : 0;

            next unless $inc;

            my @ii_lines = $self->_join_lines($ii_sec);

            push @lines, 
                $delim,
                '%% ' . $_,
                $delim,
                @ii_lines
            ;
            next;
        };

        m/$pats->{iifig}/ && do {
            my $fig_sec   = 'fig.' . $1;
            my @fig_lines = $self->_join_lines($fig_sec);

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
                        push @files,$_;
                    }
                }
            } 
    },@$dirs
    );

    return @files;
}

sub _bu_cmds_pdflatex {
    my ($self, $ref) = @_;

    my $proj    = $self->{proj};
    $ref ||= {};
    my $dir = $ref->{dir} || '';

    my $opts = [
        #'-interaction=nonstopmode'
    ];

    my @cmds;
    my $tex     = sprintf('pdflatex %s %s',join(" ",@$opts),$proj);
    my $bib_tex = sprintf('bibtex %s',$proj);

    my @texindy;
    my @files_idx = $self->_find_([$dir],[qw(idx)]);

    foreach my $idx (@files_idx) {
        local $_ = $idx;

        my $cmd;

        m/^(.*)\.eng\.idx$/ && do {
            my $xdy = qq{$1.eng.xdy};
            $cmd = sprintf(qq{ texindy -L english %s $idx }, -e $xdy ? qq{ -M $xdy } : '');
        };

        #m/\.rus\.idx$/ && do {
            #$cmd = qq{ texindy -C utf8 -L russian $_ };
        #};

        #$cmd = qq{ texindy -C utf8 -L russian $_ };

        push @texindy, $cmd;
    }
    
    my @ind_ins_bmk;
    push @ind_ins_bmk,
        qq{ call ind_ins_bmk $proj.ind 1 },
        qq{ call ind_ins_bmk index.rus.ind 1 },
        qq{ call ind_ins_bmk index.rus.ind 1 },
        ;

    push @cmds,
        $tex, $bib_tex,
        @texindy, @ind_ins_bmk,
        $tex,
        $tex,
        ;
    return @cmds;
}

sub cmd_build_pwg {
    my ($self) = @_;

    my $proj    = $self->{proj};
    my $src_dir = $self->{src_dir};

    mkpath $self->{src_dir} if -d $self->{src_dir};
    $self->cmd_insert_pwg;

    my @pdf_files;

    mkpath $self->{out_dir_pdf_pwg};
    push @pdf_files,
        catfile($src_dir,$proj . '.pdf'),
        catfile($self->{out_dir_pdf_pwg},$proj . '.pdf'),
        ;
    foreach my $f (@pdf_files) {
        rmtree $f if -e $f;
    }

    my $pdf_file = catfile($src_dir,$proj . '.pdf'),

    chdir $src_dir;

    my @cmds = $self->_bu_cmds_pdflatex;

    foreach my $cmd (@cmds) {
        system($cmd);
    }

    my @dest;
    push @dest, 
        $self->{out_dir_pdf_pwg},
        $self->{out_dir_pdf}
        ;

    if (-e $pdf_file) {
        foreach(@dest) {
            mkpath $_ unless -d;

            my $d = catfile($_, basename($pdf_file));

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

    my $jfile  = $self->_file_joined;
    my @jlines = read_file $jfile;

    my @nlines;
    my $width = 0.5;

    my ($is_img, $is_fig, $is_cmt);

    my (@tags, %opts);
    my $tags_projs = [ qw(projs), $self->{root_id}, $self->{proj} ];

    foreach(@jlines) {
        chomp;

        m/^\s*\\ifcmt/ && do { 
            $is_cmt = 1;
            next;
        };

        m/^\s*\\fi/ && do { 
            $is_cmt = 0;
            next;
        };

        unless($is_cmt){
            push @nlines, $_;
            next;
        }

        m/^\s*opts\s+(.*)$/ && do { 
            my $opts = $1;
            %opts = map { $_ => 1 } split("," => $opts);
            next;
        };

        m/^\s*fig_begin/ && do { 
            $is_fig = 1; 

            push @nlines,
                q{ \\begin{figure}[ht] };

            next;
        };

        m/^\s*fig_end/ && do { 
            $is_fig = 0; 

            push @nlines,
                q{ \\end{figure} };
            
            next;
        };

        m/^\s*img_begin/ && do { 
            $is_img = 1; next;
        };

        m/^\s*img_end/ && do { 
            $is_img = 0; 

            my @tags_all;
            unless ($opts{use_any}) {
                push @tags, $tags_projs;
            }
            foreach my $tline (@tags) {
                my $tt = join("," => @$tline);

                push @tags_all, $tt;
                push @nlines, 
                    q{%tags: } . $tt;
            }

            my $pwg = Plg::Projs::Piwigo::SQL->new;
            local @ARGV = qw( -c img_by_tags );
            push @ARGV, 
                qw( -t ), join("," => @tags_all);

            $pwg->run;
            my @img = @{$pwg->{img} || []};
            if (@img == 1) {
                my $i = shift @img;
                my $ipath = $i->{path};
                my $icapt = $i->{comment} || '';
                $icapt =~ s/\r\n/\n/g;

                push @nlines,
                    sprintf('\\includegraphics[width=%s\\textwidth]{%s}', $width, $ipath);

                if ($is_fig) {
                    push @nlines, sprintf('\\caption{%s}',$icapt);
                }
            }else{
            }

            @tags = ();
            @tags_all = ();
            %opts = ();
            
            next;
        };

        m/^\s*width\s+(.*)/ && do { 
            next unless $is_img;

            $width = $1; next;
        };

        m/^\s*tags\s+(.*)/ && do { 
            next unless $is_img;

            my $tags = $1;
            $tags =~ s/\s+//g;

            push @tags, [ split("," => $tags) ];

            next;
        };

    }
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
    my $proj = $self->{proj};

    my %f = (
        '_clean.bat' => sub { 
            [
                'rm *.xdy',
                'rm *.ind',
                'rm *.idx',
                'latexmk -C'
            ];
        },
        '_latexmk_pdf.bat' => sub { 
            [
                sprintf('latexmk -pdf %s',$proj)
            ];
        },
        '_view.bat' => sub { 
            [
                sprintf('call %s.pdf',$proj)
            ];
        },
        '_pdflatex.bat' => sub { 
            my @cmds;
            push @cmds, 
                sprintf('run_pdflatex %s',$proj)
                ;
            return [@cmds];
        },
    );
    while( my($f,$l) = each %f ){
        my $bat = catfile($dir,$f);
        my $lines = $l->();
        write_file($bat,join("\n",@$lines) . "\n");
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
    my ($self) = @_;

    if (my $cmd = $self->{opt}->{cmd}) {
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
    system(qq{ texindy -L russian -C utf8 $proj.idx });

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
