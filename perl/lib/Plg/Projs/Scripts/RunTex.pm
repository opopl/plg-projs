
package Plg::Projs::Scripts::RunTex;

use strict;
use warnings;
use utf8;

binmode STDOUT,':encoding(utf8)';

use Plg::Projs::Build::Maker;
use Plg::Projs::Prj::Builder;

use FindBin qw($Bin $Script);
use Cwd;
use Data::Dumper qw(Dumper);
use Base::Enc qw( unc_decode );

use XML::LibXML;
use XML::LibXML::PrettyPrint;

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

sub ht_pretty_print {
    my ($self,$ref) = @_;
    $ref ||= {};

    my $file = $ref->{file};

    my $ht = $self->{tex4ht} || {};

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

sub run {
    my ($self) = @_;

    my $mkx = $self->{mkx};

    my $root = $self->{root};
    my $proj = $self->{proj};
    my $tex  = $self->{tex_exe};

    my $sub_pi = $self->_sub_gen_print_index;

    my $r = { 
        dir  => $root,
    };
    my $do_htlatex = $self->_do_htlatex;

    if ($do_htlatex) {
       my $ht = $self->{tex4ht} || {};
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
            sprintf('htlatex %s %s', $proj, $proj) . qq{ '-cunihtf -utf8'} 
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
            my $code = system("$_");
            $ok &&= $code ? 0 : 1;
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
 
