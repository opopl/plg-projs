
package Plg::Projs::Scripts::RunPdfLatex;

use strict;
use warnings;

use Plg::Projs::Build::PdfLatex;

use FindBin qw($Bin $Script);
use Cwd;
use Data::Dumper qw(Dumper);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}


sub init {
    my $self = shift;

    unless (@ARGV) {
        print qq{
            USAGE:
                $Script PROJ
        } . "\n";
        exit 1;
    }

    my $proj = shift @ARGV;
    my $root = getcwd();

    my $blx = Plg::Projs::Build::PdfLatex->new( 
        skip_get_opt => 1,
        proj         => $proj,
        root         => $root,
    );

    my $h = {
        proj => $proj,
        root => $root,
        blx  => $blx,
    };
        
    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

    return $self;
}

sub run { 
    my ($self) = @_;

    my $blx = $self->{blx};

    my $root = $self->{root};
    my $proj = $self->{proj};

    my $r = { 
        dir  => $root,
    };
    my @cmds; 
    push @cmds, 
        $blx->_cmd_pdflatex,
        $blx->_cmd_bibtex,
        ;

    my $i = 1;
    while (@cmds) {
        #last if $i > 1;

        my $cmd = shift @cmds;
        local $_ = $cmd;

        system("$_");
        /^\s*pdflatex\s+/ && ($i == 1) && do { 
            my @texindy = $blx->_cmds_texindy({ dir => $root });
            unshift @cmds, @texindy;
        };

        /^\s*bibtex\s+/  && do { 
            push @cmds, 
                $blx->_cmd_pdflatex,
                $blx->_cmd_pdflatex;
        };

        $i++;

    }

    return $self;
};

1;
 
