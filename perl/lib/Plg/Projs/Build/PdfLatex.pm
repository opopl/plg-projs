
package Plg::Projs::Build::PdfLatex;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Path qw( mkpath rmtree );
use File::Basename qw(basename dirname);
use File::Copy qw( copy );
use FindBin qw($Bin $Script);
use Plg::Projs::Piwigo::SQL;

use utf8; 
use Encode;
#use open qw(:utf8 :std);
binmode STDOUT, ":utf8";

#use File::Slurp qw(
#qw(
#  append_file
  #edit_file
  #edit_file_lines
  #read_file
  #write_file
  #prepend_file
#);

#
use File::Dat::Utils qw(readarr);

use File::Slurp::Unicode;
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

sub process_ind_file {
    my ($self, $ind_file, $level) = @_;

    unless (-e $ind_file){
        return $self;
    }

   my %ind_items;

   my @out;
   my $theindex=0;
   open(F,"<:encoding(utf-8)", "$ind_file") || die $!;

   my $i=0;
   while(<F>){
       chomp;
       m/^\\begin\{theindex\}/ && do { $theindex=1; };
       m/^\\end\{theindex\}/ && do { $theindex=0; };
       next unless $theindex;

       m/^\s*\\item\s+(\w+)/ && do { $ind_items{$1} = []; };

       m{^\s*\\lettergroup\{(.+)\}$} && do {
           s{
               ^\s*\\lettergroup\{(.+)\}$
           }{
            \\hypertarget{ind-$i}{}\n\\bookmark[level=$level,dest=ind-$i]{$1}\n 
            \\lettergroup{$1}
           }gmx;

           $i++;
       };

       push @out, $_;

   }
   close(F);
   write_file($ind_file,join("\n",@out) . "\n");

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

sub cmd_build_pwg {
    my ($self) = @_;

    mkpath $self->{src_dir} if -d $self->{src_dir};
    $self->cmd_insert_pwg;

    my @pdf_files;

    mkpath $self->{out_dir_pdf_pwg};
    push @pdf_files,
        catfile($self->{src_dir},$self->{proj} . '.pdf'),
        #catfile($self->{out_dir_pdf},$self->{proj} . '.pdf'),
        catfile($self->{out_dir_pdf_pwg},$self->{proj} . '.pdf'),
        ;
    foreach my $f (@pdf_files) {
        rmtree $f if -e $f;
    }

    my $pdf_file = catfile($self->{src_dir},$self->{proj} . '.pdf'),

    my $rc = 'latexmkrc';
    my $opts = {
        latexmk => qq{ -pdf -silent -norc -r $rc }
    };

    my $cmd = sprintf("latexmk %s %s",$opts->{latexmk}, $self->{proj});
    chdir $self->{src_dir};

    my @rc_lines;
    push @rc_lines,
        q{$makeindex = 'texindy -L russian -C utf8'; },
        q{  },
        q{$pdf_mode = 1; },
        ;

    write_file($rc,join("\n",@rc_lines) . "\n");

    system(sprintf('pdflatex %s %s','-interaction=nonstopmode',$self->{proj}));
    system($cmd);

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

    my $pwg = Plg::Projs::Piwigo::SQL->new;

    $self
        ->cmd_join
        ->copy_sty
        ->copy_bib
        ;

    my $jfile  = $self->_file_joined;
    my @jlines = read_file $jfile;

    my @nlines;
    my $width = 0.5;

    my ($is_img, $is_fig, $is_cmt);

    my @tags;
    push @tags, 
        [ qw(projs), $self->{root_id}, $self->{proj} ]
        ;

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
            foreach my $tline (@tags) {
                my $tt = join("," => @$tline);

                push @tags_all, $tt;
                push @nlines, 
                    q{%tags: } . $tt;
            }

            local @ARGV = qw( -c img_by_tags );
            push @ARGV, 
                qw( -t ), join("," => @tags_all);
            $pwg->run;
            my $ipath = $pwg->{img}->{path};
            my $icapt = $pwg->{img}->{comment} || '';
            $icapt =~ s/\r\n/\n/g;

            push @nlines,
                sprintf('\\includegraphics[width=%s\\textwidth]{%s}', $width, $ipath);

            if ($is_fig) {
                push @nlines, sprintf('\\caption{%s}',$icapt);
            }
            
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

sub copy_bib {
    my ($self) = @_;

    my $root = $self->{root};

    my @bib; 
    push @bib, 
        $self->_file_sec('_bib_');

    mkpath $self->{src_dir};

    foreach(@bib) {
        my $bib_src     = $_;
        my $bib_dest    = catfile($self->{src_dir},basename($_));

        copy($bib_src, $bib_dest);
    }

    return $self;
}

sub copy_sty {
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
    #$self->process_ind_file($ind_file, 1);;

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
