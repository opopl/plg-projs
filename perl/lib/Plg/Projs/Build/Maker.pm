
if (0) {
    my $vim =<< 'eof';

TgUpdate perl_inc_plg_projs

eof
}

package Plg::Projs::Build::Maker;

use utf8;
use strict;
use warnings;

use File::stat;

use File::Spec::Functions qw(catfile);
use File::Basename qw(basename dirname);
use File::Slurp::Unicode;

use File::stat;
use File::Path qw( mkpath rmtree );
use File::Copy qw( copy );

use Cwd;

use FindBin qw($Bin $Script);
use File::Find qw(find);

use Plg::Projs::Piwigo::SQL;

use base qw(
    Base::Obj
    Base::Opt

    Plg::Projs::Build::Maker::IndFile
    Plg::Projs::Build::Maker::Bat
    Plg::Projs::Build::Maker::Join
    Plg::Projs::Build::Maker::Line
    Plg::Projs::Build::Maker::Sec
    Plg::Projs::Build::Maker::Pats
    Plg::Projs::Build::Maker::Pwg
);

use Base::Arg qw(
    hash_update
    hash_inject
);

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
    my $mkr = bless (\%opts, ref ($class) || $class);

    $mkr->init if $mkr->can('init');

    return $mkr;
}

      
sub get_opt {
    my ($mkr) = @_;

    return $mkr if $mkr->_val_('skip get_opt');

    my (%opt, @optstr, $cmdline);
    
    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));
    
    @optstr = ( 
        "cmd|c=s",
    );

    $mkr->{root}    ||= getcwd();
    $mkr->{root_id} = basename($mkr->{root});

    unless( @ARGV ){ 
        $mkr->dhelp;
        exit 0;
    }else{
        $mkr->{proj}    = shift @ARGV;

        $cmdline = join(' ',@ARGV);
        GetOptions(\%opt,@optstr);
        $mkr->{opt} = {%opt};
    }

    foreach my $x (qw(cmd)) {
        $mkr->{$x} = $mkr->{opt}->{$x};
    }

    return $mkr;    
}

sub dhelp {
    my ($mkr) = @_;

    my $pack = __PACKAGE__;
    my $s = qq{

    PACKAGE:
        $pack
    USED BY:
        projs#action#async_build_bare 
        PA async_build_bare ;;ab
    SCRIPT:
        $0
    ROOT:
        $mkr->{root}
    ROOT_ID:
        $mkr->{root_id}
    USAGE
        $Script PROJ OPTIONS
    OPTIONS
        --cmd -c CMD 

    EXAMPLES
        perl $Script aa 
        perl $Script aa -c copy_to_builds
    };

    print $s . "\n";

    return $mkr;    
}

sub init {
    my ($mkr) = @_;

    $mkr->get_opt;

    my $tex_opts_a = [];

    my $proj    = $mkr->{proj};

    my $root    = $mkr->{root} || '';
    my $root_id = $mkr->{root_id} || '';

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
        out_dir_pdf     => catfile($pdfout, $root_id, $proj),
        out_dir_pdf_pwg => catfile($pdfout, $root_id, $proj, qw(pwg) ),
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
        pwg_root_unix => $pwg->{pwg_root_unix},
        pwg_root      => $pwg->{pwg_root},
        src_dir       => catfile($h->{build_dir},qw( .. src)),
        tex_opts      => $tex_opts,
        tex_opts_a    => $tex_opts_a,
        out_dir_pdf_b => catfile($h->{out_dir_pdf}, qw(b_pdflatex) )
    };

    hash_inject($mkr, $h);

    return $mkr;
}



sub _find_ {
    my ($mkr, $dirs, $exts) = @_;

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
    my ($mkr, $ref) = @_;

    my $proj    = $mkr->{proj};

    my $cmd = sprintf('bibtex %s',$proj);

    return $cmd;
}

sub _cmd_tex {
    my ($mkr, $ref) = @_;

    my $opts = [
        '-interaction=nonstopmode',
        '-file-line-error',
    ];

    my $proj    = $mkr->{proj};

    my $cmd     = sprintf('%s %s %s',$mkr->{tex_exe},join(" ",@$opts),$proj);

    return $cmd;
}

sub _cmds_texindy {
    my ($mkr, $ref) = @_;

    my $proj = $mkr->{proj};

    $ref ||= {};
    my $dir = $ref->{dir} || '';

    my @files_idx = $mkr->_find_([$dir],[qw(idx)]);

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
        $cmd_ind = ( $^O eq 'MSWin32' ) ? 
            qq{call ind_ins_bmk.bat $proj.ind 1 } : 
            qq{ind_ins_bmk.sh $proj.ind 1 }  
            ;

        m/^(.*)\.(\w+)\.idx$/ && do {
            my $core = $1;
            my $lng = $2;

            $xdy = qq{$core.$lng.xdy};
            my $lang = $langs->{$lng};

            $M_xdy = ( -e $xdy ) ? qq{ -M $xdy } : '';
            $M_xdy ||= ( -e "index.$lng.xdy" ) ? qq{ -M index.$lng.xdy } : '';

            my $enc = ( $lng eq 'rus' ) ? '-C utf8' : '';

            $cmd_idx = sprintf(qq{texindy $enc -L $lang $M_xdy $idx });
            $cmd_ind = ( $^O eq 'MSWin32' ) ? 
                qq{call ind_ins_bmk.bat $core.$lng.ind 1 } : 
                qq{ind_ins_bmk.sh $core.$lng.ind 1 }  
            ;
        };

        push @cmds, 
            $cmd_idx, 
            $cmd_ind
            ;
    }


    return @cmds;
}

sub _files_pdf_pwg {
    my ($mkr) = @_;

    my $proj    = $mkr->{proj};
    my $src_dir = $mkr->{src_dir};

    my @pdf_files;
    push @pdf_files,
        catfile($src_dir,$proj . 'jnd.pdf'),
        catfile($mkr->{out_dir_pdf_pwg},$proj . '.pdf'),
        ;

    return @pdf_files;

}



sub cmd_join {
    my ($mkr) = @_;

    $mkr->_join_lines;

    return $mkr;
}

sub create_bat_in_src {
    my ($mkr) = @_;

    my $dir  = $mkr->{src_dir};

    my $proj    = $mkr->{proj};
    my $root_id = $mkr->{root_id};

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

###f_bat
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
            my $pdf   = 'jnd.pdf';
            my $cmd   = ( $^O eq 'MSWin32' ) ? 'call' : 'evince';
            my $after = ( $^O eq 'MSWin32' ) ? '' : ' &';

            my $s = sprintf('%s %s%s',$cmd,$pdf,$after);
            return [ $s ];
        },
##_bat_xelatex
        '_xelatex' => $mkr->_bat_sub_tex({ 
            times => 2,
            exe   => 'xelatex' 
        }),
        '_pdflatex' => $mkr->_bat_sub_tex({ 
            times => 2,
            exe   => 'pdflatex' 
        }),
##_bat__run_tex
        '_run_tex' => sub { 
            my $call = ( $^O eq 'MSWin32' ) ? 'call ' : '';
            my $dir = ( $^O eq 'MSWin32' ) ? q{} : q{./};
            my $args = ( $^O eq 'MSWin32' ) ? q{%*} : q{$*};

            my @cmds;
            if ($^O eq 'MSWin32'){
                push @cmds, ' ','@echo off',' ';
            }else{
                push @cmds, '#!/bin/sh',' ';
            }
            push @cmds, 
                sprintf('%s%s%s',$call, $dir, $mkr->_bat_file('_clean')),
                sprintf('%s jnd %s', $mkr->_bat_file('run_tex'), $args),
                ;
            return [@cmds];
        },
    );

    while( my($f,$l) = each %f_bat ){
        my $fl = $mkr->_bat_file($f);

        my $bat_path = catfile($dir,$fl);
        my $lines = $l->();

        write_file($bat_path,join("\n",@$lines) . "\n");
        chmod 0755, $bat_path;

    }

    return $mkr;
}

sub copy_to_src {
    my ($mkr) = @_;

    mkpath $mkr->{src_dir};

    $mkr
        ->copy_bib_to_src
        ->copy_sty_to_src
        ;

    return $mkr;
}

sub copy_bib_to_src {
    my ($mkr) = @_;

    my $root = $mkr->{root};

    my @bib; 
    push @bib, 
        $mkr->_file_sec('_bib_');


    foreach(@bib) {
        my $bib_src     = $_;
        my $bib_dest    = catfile($mkr->{src_dir},basename($_));

        copy($bib_src, $bib_dest);
    }

    return $mkr;
}

sub copy_sty_to_src {
    my ($mkr) = @_;

    my $root = $mkr->{root};

    my @sty; 
    push @sty, 
        qw(projs.sty);

    mkpath $mkr->{src_dir};

    foreach(@sty) {
        my $sty_src     = catfile($root,$_);
        my $sty_dest    = catfile($mkr->{src_dir},$_);

        copy($sty_src, $sty_dest);
    }

    return $mkr;
}

sub cmd_copy_to_builds {
    my ($mkr) = @_;

    my $proj = $mkr->{proj};
    my $root = $mkr->{root};

    my $dbfile = $mkr->{dbfile};

    my $dbh = dbi_connect({
        dbfile => $mkr->{dbfile},
    });

    my $ref = {
        dbh     => $dbh,
        t       => 'projs',
        f       => [qw(file)],
        p       => [$proj],
        cond    => qq{ WHERE proj = ? },
    };
    $mkr->{files} = dbh_select_as_list($ref);
    mkpath $mkr->{src_dir};

    foreach my $file (@{ $mkr->{files} || [] }) {
        my $path = catfile($root,$file);
        copy($path, $mkr->{src_dir} );
    }

    return $mkr;
}

sub run_cmd {
    my ($mkr, $ref) = @_;

    $ref ||= {};
    my $cmd = $ref->{cmd} || $mkr->{cmd};

    if ($cmd) {
        my $sub = 'cmd_'.$cmd;
        if ($mkr->can($sub)) {
            $mkr->$sub;
        }else{
            warn "No command defined: " . $cmd . "\n";
            exit 1;
        }
        exit 0;
    }

    return $mkr;
}

sub run {
    my ($mkr) = @_;

    $mkr->run_cmd;
    
    return $mkr;
}

sub cmd_bare {
    my ($mkr) = @_;

    mkpath $mkr->{build_dir};

    my $proj = $mkr->{proj};
    my $root = $mkr->{root};

    my @dirids = qw( 
        out_dir 
        out_dir_pdf 
        out_dir_pdf_b 
        out_dir_pdf_pwg
    );

    foreach my $dirid (@dirids) {
        my $dir = $mkr->{$dirid};
        mkpath $dir;
    }

    my $proj_bib = catfile( $mkr->{out_dir}, "$proj.bib" );
    copy( $mkr->{bib_file}, $proj_bib ) 
        if -e $mkr->{bib_file};
    
    my $cmd_tex = join(" ", @$mkr{qw( tex_exe tex_opts )}, $proj );
    system($cmd_tex);

    chdir $mkr->{build_dir};
    
    system(qq{ bibtex $proj } ) if -e $proj_bib;

    my $idx = "$proj.idx";
    if (-e $idx) {
        system(qq{ texindy -L russian -C utf8 $idx });
    }

    my $ind_file = catfile("$proj.ind");
    #$mkr->ind_ins_bmk($ind_file,1);

    #return ;
    chdir $mkr->{root};

    system($cmd_tex);
    system($cmd_tex);

    my $built_pdf = catfile($mkr->{build_dir}, "$proj.pdf");

    if (! -e $built_pdf) {
        warn 'NO PDF FILE!' . "\n";
        return;
    }

    my @pdf_files;
    push @pdf_files, 
        catfile($mkr->{out_dir_pdf_b},"$proj.pdf"),
        catfile($mkr->{out_dir_pdf},"$proj.pdf"),
        ;

    foreach my $dest (@pdf_files) {
        copy($built_pdf, $dest);

        if (-e $dest) {
            print "Copied generated PDF to: " . "\n";
            print "     $dest" . "\n";
        }
    }

    return $mkr;

}
# end of cmd_bare

1;
