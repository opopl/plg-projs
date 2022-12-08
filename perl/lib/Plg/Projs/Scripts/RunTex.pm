
package Plg::Projs::Scripts::RunTex;

use strict;
use warnings;
use utf8;

binmode STDOUT,':encoding(utf8)';
use open qw/:std :utf8/;

use Plg::Projs::Build::Maker;
use Plg::Projs::Prj::Builder;

use Encode;
use DateTime;

use FindBin qw($Bin $Script);
use Cwd;
use Data::Dumper qw(Dumper);
use Base::Enc qw( unc_decode );
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);
use File::Copy qw(copy);

use XML::LibXML;
use XML::LibXML::PrettyPrint;

use Capture::Tiny qw(capture);

use File::stat;
use File::Path qw(rmtree);
use File::Slurp::Unicode;

use Plg::Projs::Tex::Tex4ht qw(
    ht_cnf2txt
);

use Getopt::Long qw(GetOptions);
use JSON::XS;


use Base::Arg qw(
    hash_inject

    varval
);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub _sub_gen_print_index {
    my ($self) = @_;

    sub {
        my $obj_bld = $self->{obj_bld};
        return $self unless $obj_bld;

        my @pi_lines = $obj_bld->_bld_ind_printindex;
        #unshift @pi_lines,
            #q{%this file is generated by: },
            #q{%     Plg::Projs::Scripts::RunTex      _sub_gen_print_index() },
            #q{%     Plg::Projs::Prj::Builder::Sct    _bld_ind_printindex() },
            #q{%begin_file},
            ;

        my $pi_file = q{print_index.tex};
        if (@pi_lines) {
          write_file($pi_file,join("\n",@pi_lines) . "\n");
          print qq{[RunTex] writing: $pi_file } . "\n";
        }

        return $self;
    };
}

sub json_load {
    my ($self) = @_;

    my $j_file = 'run_tex.json';
    if (!-e $j_file) {
        warn qq{[RunTex] JSON input file absent: $j_file} . "\n";
        return $self;
    }

    my $json = read_file $j_file;
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
    my $h = $coder->decode($json);

    my $in_data = $self->{in_data} = $h;

    my $ind = $in_data->{bld}->{ind} || [];
    my $obj_bld =  Plg::Projs::Prj::Builder->new(
        root    => $in_data->{root} || '',
        root_id => $in_data->{root_id} || '',
        proj    => $in_data->{proj} || '',

        prj_skip_db       => 1,
        prj_skip_load_xml => 1,

        bld_skip_init     => 1,
        preamble => {
            index => {
                ind => $ind,
            },
        }
    );
    $self->{obj_bld} = $obj_bld;
    print Dumper($ind) . "\n";

    return $self;
}

sub init {
    my $self = shift;

    return $self if $self->{skip_init};

    my $h = {
        tex_exe => 'xelatex',
    };
    hash_inject($self, $h);

    $self
        ->get_proj
        ->json_load
        ->get_opt
        ->init_mkx
        ;

    return $self;
}

sub get_proj {
    my ($self) = @_;

    my $pack = __PACKAGE__;

    return $self if $self->{skip_get_opt};

    unless (@ARGV) {
        print qq{
            PACKAGE:
                $pack
            LOCATION:
                $0
            USAGE:
                perl $Script PROJ
        } . "\n";
        exit 1;
    }

    my $proj = shift @ARGV;
    my $root = getcwd();

    my $h = {
        proj => $proj,
        root => $root,
    };
    hash_inject($self, $h);

    return $self;
}


sub get_opt {
    my ($self) = @_;

    return $self if $self->{skip_get_opt};

    my (%opt, @optstr);

    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));

    @optstr = (
        "tex_exe|x=s",
    );

    if(@ARGV){
        GetOptions(\%opt,@optstr);
    }

    foreach my $x (qw(tex_exe)) {
        next unless defined $opt{$x};

        $self->{$x} = $opt{$x};
    }


    return $self;
}

sub init_mkx {
    my ($self) = @_;

    $self->{mkx} ||= Plg::Projs::Build::Maker->new(
        skip => { get_opt => 1 },
        proj         => $self->{proj},
        root         => $self->{root},
        tex_exe      => $self->{tex_exe},
    );

    return $self;
}

sub rm_zero {
    my ($self,$exts) = @_;

    my $mkx  = $self->{mkx};

    my $root = $self->{root};

    my @files = $mkx->_find_([$root],$exts);

    foreach my $f (@files) {
        my $st = stat($f);
        my $size = $st->size;

        unless ($size) {
            print $f . "\n";
            rmtree($f);
            next;
        }
    }

    return $self;
}

sub run_after {
    my ($self) = @_;

    my $do_htlatex = $self->_do_htlatex;
    return $self unless $do_htlatex;

    my $ht = $self->{tex4ht} || {};

    $self->ht_pretty_print;

    return $self;
}

sub ht_load_dom {
    my ($self,$ref) = @_;
    $ref ||= {};

    return $self;
}

sub ht_pretty_print {
    my ($self,$ref) = @_;
    $ref ||= {};

    my $file = $ref->{file};

    my $ht = $self->{tex4ht} || {};
    my $run_after = $ht->{run_after} || {};

    unless ($file) {
        my @ht_files = File::Find::Rule
            ->new->name('*.html')->in('.');
        foreach my $ht_file (@ht_files) {
            $self->ht_pretty_print({ file => $ht_file });
        }
        return $self;
    }

    my $html = read_file $file;

    $XML::LibXML::skipXMLDeclaration =
        $ref->{libxml_skip_xml_decl} || $self->{libxml_skip_xml_decl};
    my $opts_prettyprint = $ref->{opts_prettyprint} || {};

    my $defs = {
        expand_entities => 0,
        load_ext_dtd    => 1,
        no_blanks       => 1,
        no_cdata        => 1,
        line_numbers    => 1,
    };

    my $parser = XML::LibXML->new(%$defs);

    my $string = $ref->{decode} ? unc_decode($html) : $html;
    my $inp = {
        string          => $string,
        recover         => 1,
        suppress_errors => 1,
    };
    my $dom = $parser->load_html($inp);
    my $node = $dom;

    $DB::single = 1;
    $dom->findnodes('//pre/text()')->map(
        sub { my ($node) = @_;
            my $parent = $node->parentNode;
            local $_ = $node->getData();
            #s/^\s*$//g;
            #$parent->removeChild($node) unless $data;
            #print qq{$_} . "\n" if /\n\n/;
        }
    );

    $dom->findnodes('//pre[contains(@class,"fancyvrb")]/a')->map(
        sub { my ($node) = @_;
            my $parent = $node->parentNode;
            $parent->removeChild($node);
        }
    );

    $dom->findnodes('//pre[contains(@class,"verbatim")]/span')->map(
        sub {
            my ($node) = @_;

            my $parent = $node->parentNode;
            my $text   = $node->textContent || '';

            my $new    = $dom->createTextNode($text);

            $parent->replaceChild( $new, $node );
        }
    );

    my $txt;
    $dom->findnodes('//pre[contains(@class,"fancyvrb")]')->map(
        sub {
            my ($node) = @_;
            $txt = $node->textContent;
            $node->findnodes('./text()')->map(
                sub { my ($t) = @_;
                    my $p = $t->parentNode;
                    $p->removeChild($t);
                }
            );
            my $tt = $dom->createTextNode($txt);
            $node->addChild($tt);
        }
    );
    $DB::single = 1;

    $dom->findnodes('//pre/text()')->map(
        sub { my ($node) = @_;
            local $_ = $node->getData();
            s/’/'/g;
            $node->setData($_);
        }
    );

    if ($run_after->{js}) {
        $dom->findnodes('//body')->map(
            sub { my ($node) = @_;
                my $js = $dom->createElement('script');
                my $src = join("/" => qw( .. .. .. ctl js dist bundle.js ));
                $js->setAttribute( src => $src );
                $node->appendChild($js);
            }
        );
    }

    #my @block = qw/table tables columns entry latex_table options/;
    my @block = qw//;
    my %cb = (
        compact =>  sub {
            my $node = shift;
            my $name = $node->nodeName;
            return 0 if grep { /^$name$/ } @block;
            return 1;
        },
    );
    my $pp = XML::LibXML::PrettyPrint->new(
        indent_string => "  ",
        element => {
            inline   => [qw/span/],
            block    => [@block],
            #compact  => [qw//,$cb{compact}],
            preserves_whitespace => [qw/pre/],
        },
        %$opts_prettyprint,
    );
    $pp->pretty_print($node);

    my $text = $dom->toStringHTML;
    write_file($file,$text);

    return $self;
}

sub _do_htlatex {
    my ($self) = @_;

    my $do_htlatex = $self->{do_htlatex} || $self->{obj_bld}->{do_htlatex};
    return $do_htlatex;
}

sub shell {
    my ($self, $ref) = @_;
    $ref ||= {};

    my (@stdout, @stderr, $code);

    my ($cmd, $shell, $do_htlatex) = @{$ref}{qw( shell do_htlatex )};
    my ($ht_run, $obj_bld) = @{$ref}{qw( ht_run obj_bld )};

    $DB::single = 1;
    if ($shell eq 'system') {
        $code = system("$_");
    }else{
        print '[RUNTEX] start cmd: ' . $cmd . "\n";
        my ($start, $end, $elapsed);

        $start = DateTime->now->epoch;
        eval {
            my ($o, $e);
            local $SIG{__WARN__} = sub {};
            ($o, $e, $code) = capture {
                #binmode(STDOUT, ":utf8");
                system("$_");
            };

            push @stdout, split("\n",$o);
            push @stderr, split("\n",$e);
        };
        $end = DateTime->now->epoch;
        $elapsed = $end - $start;

        if ($@) {
            warn $@ . "\n";
        }else{
            print '[RUNTEX] end cmd: ' . $cmd . "\n";
            print '[RUNTEX] exit code: ' . $code . "\n";
        }

        if ($code) {
           if ($do_htlatex) {
               my @tail = splice @stdout, -30, -1;
               print $_ . "\n" for(@tail);

               my %err;
               for(@tail){
                  /^(?<file>\S+):(?<lnum>\d+):\s*(LaTeX Error|Emergency stop)/ && do {
                      $err{$_} = $+{$_} for keys %+;
                      next;
                  };
               }
               my @err_block;
               my @lines = read_file $err{file};
               my $j = 0;
               my $size = 20;
               my ($err_sec,$here);
               for(@lines){
                  chomp;
                  $j++;

                  my (@marker);

                  /^%%sec\.here\s+(\S+)/ && do { $here = $1; };
                  $err_sec = $here if $j == $err{lnum};

                  next if $j > $err{lnum} + $size || $j < $err{lnum} - $size;
                  my $str = sprintf('%d: %s', $j, $_);

                  ($err{lnum} == $j) && do { push @marker, '-' x 50 };

                  push @err_block, @marker, $str, @marker;
               }
               #print Dumper(\%err) . "\n";
               #print Dumper(\@err_block) =~ s/\\x\{([0-9a-f]{2,})\}/chr hex $1/ger;
               my $fpath = catfile(getcwd(), basename($err{file}));
               $self->{err} = {
                   %err,
                   block => \@err_block,
                   file => $fpath,
                   sec => $err_sec,
                   tail => [@tail],
               };
               $obj_bld->{err} = $self->{err} if $obj_bld;
               $DB::single = 1;

               if ( varval('err.die'  => $ht_run) ) {
                   die "[RUNTEX] error";
               }
           }
        }
    }

    return $self;
}

sub run {
    my ($self) = @_;

    my ($obj_bld, $mkx) = @{$self}{qw( obj_bld mkx )};

    my $root = $self->{root};
    my $proj = $self->{proj};
    my $tex  = $self->{tex_exe};

    my $sub_pi = $self->_sub_gen_print_index;

    my $r = {
        dir  => $root,
    };
    my $do_htlatex = $self->_do_htlatex;
    my $shell = $self->{shell} || $obj_bld->_vals_('run_tex.shell') || 'system';

    my ($ht, $ht_run);
    if ($do_htlatex) {
       $ht = $self->{tex4ht} || {};
       $ht_run = $ht->{run} || { 'exe' => 'htlatex' };

       my $ht_cfg = $ht->{cfg} || {};
       my @ht_txt = ht_cnf2txt($ht_cfg);

       my $ht_file = $proj . '.cfg';
       write_file($ht_file,join("\n",@ht_txt) . "\n");

       $tex = $self->{tex_exe} = $mkx->{tex_exe} = 'latex';
    }

    my @cmds;
    push @cmds,
        -f './_clean.sh' ? './_clean.sh' : (),
        $do_htlatex ? (
            #$mkx->_cmd_tex,
            #$mkx->_cmd_bibtex,
            $mkx->_cmd_ht_run({
                proj => $proj,
                run => $ht_run
            })
        ) : (
            $mkx->_cmd_tex,
            $mkx->_cmd_bibtex,
            $mkx->_cmd_tex,
            $mkx->_cmd_tex,
        )
        ;

    $DB::single = 1;

    my $i = 1;
    my $ok = 1;
    while (@cmds) {
        my $cmd = shift @cmds;

        local $_ = $cmd;

        unless(ref $cmd){
            my $r = {
               cmd        => $cmd,
               shell      => $shell,

               do_htlatex => $do_htlatex,
               ht_run     => $ht_run,
               obj_bld    => $obj_bld,
            };
            $self->shell($r);

            #$ok &&= $code ? 0 : 1;
        }elsif(ref $cmd eq 'CODE'){
            $cmd->();
            next;
        }

        $self->rm_zero([qw( idx bbl mtc maf )]);

        /^\s*$tex\s+/ && do {
            #next unless ($i == 1);
            my @texindy = $mkx->_cmds_texindy({ dir => $root });
            unshift @cmds, @texindy;
        };

        /^\s*bibtex\s+/  && do {

            $self->rm_zero([qw( bbl )]);

            my @bbl = $mkx->_find_([$root],[qw(bbl)]);

            unshift @cmds,
               $mkx->_cmd_tex,
               $sub_pi,
               ;

            if (@bbl) {
                push @cmds,
                    $mkx->_cmd_tex;
            }
        };

        $i++;

    }

    return $self;
};

1;

