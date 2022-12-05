
if (0) {
    my $vim =<< 'eof';

TgUpdate perl_inc_plg_projs

eof
}

package Plg::Projs::Build::Maker;

use utf8;
use strict;
use warnings;

use YAML::XS qw();

use base qw(
    Base::Obj
    Base::Opt

    Plg::Projs::Build::Maker::IndFile
    Plg::Projs::Build::Maker::Bat
    Plg::Projs::Build::Maker::Join
    Plg::Projs::Build::Maker::Line
    Plg::Projs::Build::Maker::Sec
    Plg::Projs::Build::Maker::Pats

    Plg::Projs::Build::Maker::Jnd
    Plg::Projs::Build::Maker::Tree
    Plg::Projs::Build::Maker::Html
);

use File::stat;

use File::Spec::Functions qw(catfile);
use File::Basename qw(basename dirname);
use File::Slurp::Unicode;

use JSON::XS;


use File::stat;
use File::Path qw( mkpath rmtree );
use File::Copy qw( copy );

use Cwd;

use JSON::Dumper::Compact;

use FindBin qw($Bin $Script);
use File::Find qw(find);
#use File::Find::Rule;

use Plg::Projs::Prj;



use Base::File qw(
    win2unix
);

use Base::Arg qw(
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

use Plg::Projs::Map qw(
    %tex_syms
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

sub init_prj {
    my ($mkr) = @_;

    if ($mkr->{root} && $mkr->{root_id} && $mkr->{proj}) {
        $mkr->{prj} = Plg::Projs::Prj->new(
            root   => $mkr->{root},
            rootid => $mkr->{root_id},
            proj   => $mkr->{proj},
        );
    }

    return $mkr;
}

sub init_img {
    my ($mkr) = @_;

    my $bld = $mkr->{bld};

    my ($img_root, $dbfile_img);

    if ($bld) {
        $img_root   = $bld->_bld_var('img_root');
        $dbfile_img = $bld->_bld_var('dbfile_img');
    }

    $img_root   ||= $ENV{IMG_ROOT} // catfile($ENV{HOME}, qw(img_root));
    $dbfile_img ||= catfile($img_root, qw(img.db));

    my $h = {
        img_root      => $img_root,
        img_root_unix => win2unix($img_root),
        dbfile_img    => $dbfile_img,
    };

    hash_inject($mkr, $h);

    my $ref = {
        dbfile => $mkr->{dbfile_img},
        attr   => {},
    };

    $mkr->{dbh_img} = dbi_connect($ref);

    return $mkr;
}

sub init_ii_include {
    my ($mkr) = @_;

    my @include;

    my $f_in = $mkr->_file_ii_include;

    my @i = $mkr->_val_list_(qw( sections include ));
    push @include, @i;

    my $load_dat = $mkr->_val_(qw( load_dat ii_include ));

    while(1){
        last unless $load_dat;

        if (-e $f_in) {
            push @include, readarr($f_in);
        }else{
            $mkr->{ii_include_all} = 1;
        }

        last;
    }

    $mkr->{ii_include} = \@include;

    $mkr
        ->ii_filter             # check for _base_ _all_
        ->ii_insert_updown      # handle ii_updown
        ;

    #print Dumper($mkr->_val_('sections')) . "\n";
    #print Dumper($mkr->_val_('join_lines')) . "\n";
    #print Dumper($mkr->{ii_include}) . "\n";

    return $mkr;
}

sub init {
    my ($mkr) = @_;

    $mkr->get_opt;

    my $proj    = $mkr->{proj};

    my $root    = $mkr->{root} || '';
    my $root_id = $mkr->{root_id} || '';

    my $pdfout  = $ENV{PDFOUT} || catfile($ENV{HOME},qw(out pdf));
    my $htmlout = $ENV{HTMLOUT} || catfile($ENV{HOME},qw(out html));

    my $bld    = $mkr->{bld} || {};
    my $target = $bld->{target} || '';

    my @build_dir_a = ( "builds", $proj, "b_pdflatex" );

    my $h = {
        proj            => $proj,
        pdfout          => $pdfout,
        htmlout         => $htmlout,
        tex_exe         => 'pdflatex',
        build_dir_unix  => join("/",@build_dir_a),
        build_dir       => catfile($root, @build_dir_a),
        bib_file        => catfile($root, qq{$proj.refs.bib}),
        out_dir_pdf     => catfile($pdfout, $root_id, $proj),
        out_dir_html    => catfile($htmlout, $root_id, $proj),
        dbfile          => catfile($root,'projs.sqlite'),
        cmd             => 'bare',
        ii_tree         => {},           # see _join_lines
    };
    hash_inject($mkr, $h);

    my $target_ext = $mkr->{do_htlatex} ? 'html' : 'pdf';

    $mkr
       ->init_img
       ->init_prj
       ->init_ii_include
       ;

    my $tex_opts_a = [];
    push @$tex_opts_a,
        '-file-line-error',
        '-interaction nonstopmode',
        sprintf(qq{ -output-directory=./%s}, $h->{build_dir_unix}),
        ;

    my $tex_opts = join(" ", @$tex_opts_a);

    $h = { %$h,
        src_dir       => catfile($h->{build_dir},qw( .. src ), $target_ext, $target),
        src_dir_box   => catfile($ENV{BOX}, $root_id, $proj, $target_ext, $target),
        tex_opts      => $tex_opts,
        tex_opts_a    => $tex_opts_a,
        out_dir_pdf_b => catfile($h->{out_dir_pdf}, qw(b_pdflatex) )
    };

    hash_inject($mkr, $h);

    if ($mkr->{box}) {
        mkpath $mkr->{src_dir_box};
        $mkr->{src_dir} = $mkr->{src_dir_box};
    }

    mkpath $mkr->{src_dir};

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

sub _sub_clean {
    my ($mkr, $ref) = @_;
    $ref ||= {};

    my $dir = $ref->{dir} || getcwd();
    my $exts = $ref->{exts} || [qw()];

    my $sub = sub {
        my $rule = File::Find::Rule->new;
        $rule->name(map { "*.$_" } @$exts);
        #$rule->maxdepth($max_depth) if $max_depth;

        #my @imgs = $rule->in(@$dirs);
    };

    return $sub;
}

sub _cmd_ht_run {
    my ($mkr, $ref) = @_;
    $ref ||= {};

    my $run  = $ref->{run} || { exe => 'htlatex' };
    my $exe = $run->{exe};

    my $proj = $ref->{proj} || $mkr->{proj};
    my $cfg  = $ref->{cfg} || $proj;

    my $cmd;
	my $run_argc = $run->{argc} || {};
	my $argc = { 
		tex4ht => $run_argc->{tex4ht} || q{ -cunihtf -utf8},
		t4ht   => $run_argc->{t4ht} || '',
		latex  => $run_argc->{latex} || '',
	};
	my @ord = qw(tex4ht t4ht latex);
	my $opts = join(' ' => map { qq{'$_'} } @{$argc}{@ord} );

    for($exe){
        /^htlatex$/ && do {
            $cmd = sprintf('htlatex %s %s %s', $proj, $cfg, $opts);
            last;
        };
        /^make4ht$/ && do {
            $cmd = sprintf('make4ht %s %s %s', $proj, $cfg, $opts);
            last;
        };
    }
	$DB::single = 1;

    return $cmd;
}

sub _cmd_tex {
    my ($mkr, $ref) = @_;

    my $opts = [
        '-interaction=nonstopmode',
        '-file-line-error',
    ];

    #print qq{[RunTex] run tex_exe #$tex_count} . "\n";

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

        while(1){
          last if $idx !~ /^authors/;

          my @lines = read_file $idx;
          for(@lines){
             /^\\indexentry\{(.*)\|hyperpage\}\{(\d+)\}\s*$/ &&  do {
                my $entry = $1;
                my $page = $2;
                while(my($k,$v)=each %tex_syms){
                  $entry =~ s/\Q$k\E/$v /g;
                }
                $_ = sprintf('\indexentry{%s|hyperpage}{%s}',$entry,$page)
             };
          }
          write_file($idx,join("\n",@lines) . "\n");
          last;
        }

        my ($f) = (m/^(\w+)\./);
        my $xdy = qq{$f.xdy};

        my $M_xdy = ( -e $xdy ) ? qq{ -M $xdy } : '';
        my ($cmd_idx, $cmd_ind);

        $cmd_idx = sprintf(qq{texindy $M_xdy $idx });
        $cmd_ind = ( $^O eq 'MSWin32' ) ?
            qq{call ind_ins_bmk.bat $proj.ind 1 } :
            qq{ind_ins_bmk.sh $proj.ind 1 }
            ;

        m/^(?<name>(?:|(?<pref>.*)\.)(?<lng>\w+))\.idx$/ && do {
            my $core = $+{pref};
            my $lng  = $+{lng};
            my $name = $+{name};

            #$xdy = qq{$core.$lng.xdy};
            $xdy = qq{$name.xdy};
            my $lang = $langs->{$lng} || 'english';

            $M_xdy = ( -f $xdy ) ? qq{ -M $xdy } : '';
            $M_xdy ||= ( -f "$lng.xdy" ) ? qq{ -M $lng.xdy } : '';

            my $enc = ( $lng eq 'rus' ) ? '-C utf8' : '';

            my $ind_file = "$name.ind";

            $cmd_idx = sprintf(qq{texindy $enc -L $lang $M_xdy $idx });
            $cmd_ind = ( $^O eq 'MSWin32' ) ?
                qq{call ind_ins_bmk.bat $ind_file 1 } :
                qq{ind_ins_bmk.sh $ind_file 1 }
            ;
        };

        push @cmds,
            $cmd_idx,
            $cmd_ind
            ;
    }

    return @cmds;
}

=head3 cmd_json_out

=head4 call tree

    called by
        cmd_jnd_compose

=cut

sub cmd_json_out_runtex {
    my ($mkr, $ref) = @_;
    $ref ||= {};

    my $src_dir = $ref->{src_dir} || $mkr->{src_dir};
    $src_dir = $mkr->{src_dir_box} if $ref->{box} || $mkr->{box};

    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

    my $bld = $mkr->{bld};
    my $json_file = catfile($src_dir,'run_tex.json');

    my $h = {
        bld => {
            ind => $bld->_bld_ind,
        },
        proj         => $bld->{proj},
        root         => $bld->{root},
        root_id      => $bld->{root_id},
    };

    my $j_data = $coder->encode($h);
    write_file($json_file,$j_data);

    return $mkr;
}

###print_ii_include
sub cmd_print_ii_include {
    my ($mkr) = @_;

    my @include = $mkr->_ii_include;
    print qq{$_} . "\n" for(@include);

    return $mkr;
}

###print_ii_exclude
sub cmd_print_ii_exclude {
    my ($mkr) = @_;

    my @exclude = $mkr->_ii_exclude;
    print qq{$_} . "\n" for(@exclude);

    return $mkr;
}

###print_ii_base
sub cmd_print_ii_base {
    my ($mkr) = @_;

    my @include = $mkr->_ii_base;
    print qq{$_} . "\n" for(@include);

    return $mkr;
}

sub cmd_print_ii_body {
    my ($mkr) = @_;

    my $bld = $mkr->{bld};

    my $path = 'sii.scts._main_.ii.inner.body';
    my $ii_body = $bld->_vals_($path);
    my $yaml = YAML::XS::Dump($ii_body);

    my @out;
    push @out, 'begin_yaml', $yaml, 'end_yaml';
    print join("\n",@out) . "\n";

    return $mkr;
}

###print_ii_tree
sub cmd_print_ii_tree {
    my ($mkr) = @_;

    $mkr
        ->tree_fill
        ->tree_write_fs
        ;

    #my $f_bn = basename($file_tree);

    #print qq{[proj: $proj, root_id: $root_id] Tree written to: $f_bn} . "\n";

    return $mkr;
}

sub cmd_relax {
    my ($mkr) = @_;

    return $mkr;
}

sub cmd_join {
    my ($mkr) = @_;

    # Plg::Projs::Build::Maker::Join
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
                # htlatex
                'rm *.4tc',
                'rm *.4ct',
                'rm *.mw',
                'rm *.tmp',
                'rm *.xref',
                'rm *.idv',
                'rm *.lg',
                'latexmk -C',
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
        unless (ref $cmd) {
            my $sub = 'cmd_' . $cmd;
            if ($mkr->can($sub)) {
                $mkr->$sub;
            }else{
                warn "[Maker] No command defined: " . $cmd . "\n";
                exit 1;
            }
            #exit 0;
        }
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
        out_dir_pdf
        out_dir_pdf_b
    );

    foreach my $dirid (@dirids) {
        my $dir = $mkr->{$dirid};
        mkpath $dir;
    }

    my $proj_bib = catfile( $mkr->{build_dir}, "$proj.bib" );
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
