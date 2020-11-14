
package Plg::Projs::Scripts::RunTex;

use strict;
use warnings;

use Plg::Projs::Build::Maker;

use FindBin qw($Bin $Script);
use Cwd;
use Data::Dumper qw(Dumper);

use File::stat;
use File::Path qw(rmtree);
use File::Slurp::Unicode;

use Getopt::Long qw(GetOptions);

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

sub json_load {
    my ($self) = @_;

    my $j_file = 'run_tex.json';
    if (-e $j_file) {
        my $json = read_file $j_file;
        print Dumper($json) . "\n";
        exit;
    }

    return $self;
}


sub init {
    my $self = shift;

    my $h = {
        tex_exe => 'pdflatex',
    };
    hash_inject($self, $h);

    $self
        ->get_proj
        ->json_load
        ->get_opt
        ->init_blx
        ;

    return $self;
}

sub get_proj {
    my ($self) = @_;

    my $pack = __PACKAGE__;

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

    my $blx = Plg::Projs::Build::Maker->new( 
        skip => { 
            get_opt => 1 
        },
        proj         => $proj,
        root         => $root,
    );

    my $h = {
        proj => $proj,
        root => $root,
    };
    hash_inject($self, $h);

    return $self;
}

      
sub get_opt {
    my ($self) = @_;

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

sub init_blx {
    my ($self) = @_;

    my $blx = Plg::Projs::Build::Maker->new( 
        skip => { 
            get_opt => 1 
        },
        proj         => $self->{proj},
        root         => $self->{root},
        tex_exe      => $self->{tex_exe},
    );

    my $h = {
        blx  => $blx,
    };
    hash_inject($self, $h);

    return $self;
}

sub rm_zero {
    my ($self,$exts) = @_;

    my $blx  = $self->{blx};

    my $root = $self->{root};

    my @files = $blx->_find_([$root],$exts);

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

sub run { 
    my ($self) = @_;

    my $blx = $self->{blx};

    my $root = $self->{root};
    my $proj = $self->{proj};
    my $tex  = $self->{tex_exe};

    my $r = { 
        dir  => $root,
    };
    my @cmds; 
    push @cmds, 
        $blx->_cmd_tex,
        $blx->_cmd_bibtex,
        $blx->_cmd_tex,
        ;

    my $i = 1;
    while (@cmds) {
        my $cmd = shift @cmds;

        local $_ = $cmd;

        system("$_");
        $self->rm_zero([qw( idx bbl mtc maf )]);

        /^\s*$tex\s+/ && do { 
            #next unless ($i == 1);
            my @texindy = $blx->_cmds_texindy({ dir => $root });
            unshift @cmds, @texindy;
        };

        /^\s*bibtex\s+/  && do { 

            $self->rm_zero([qw( bbl )]);
            
            my @bbl = $blx->_find_([$root],[qw(bbl)]);

            push @cmds, 
               $blx->_cmd_tex;

            if (@bbl) {
                push @cmds, 
                    $blx->_cmd_tex;
            }
        };

        $i++;

    }

    return $self;
};

1;
 
