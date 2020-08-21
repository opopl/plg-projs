
package Plg::Projs::Scripts::RunPdfLatex;

use strict;
use warnings;

use Plg::Projs::Build::PdfLatex;

use FindBin qw($Bin $Script);
use Cwd;

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

    my $blx = Plg::Projs::Build::PdfLatex->new;

    my $h = {
        proj => shift @ARGV,
        blx  => $blx,
    };
        
    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

    return $self;
}

sub run { 
    my ($self) = @_;

    my $blx = $self->{blx};

    my $r = { 
        proj => $self->{proj},
        dir  => getcwd(),
    };
    my @cmds = $blx->_bu_cmds_pdflatex($r);

    return $self;
};

1;
 
