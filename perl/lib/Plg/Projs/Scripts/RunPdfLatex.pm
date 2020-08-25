
package Plg::Projs::Scripts::RunPdfLatex;

use strict;
use warnings;

use Plg::Projs::Build::PdfLatex;

use FindBin qw($Bin $Script);
use Cwd;
use Data::Dumper qw(Dumper);

use File::stat;
use File::Path qw(rmtree);

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
            LOCATION:
				$0
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

sub rm_zero {
    my ($self,$exts) = @_;

    my $blx  = $self->{blx};

    my $root = $self->{root};

	my @files = $blx->_find_([$root],$exts);

	foreach my $f (@files) {
		my $st = stat($f);
		my $size = $st->size;

		unless ($size) {
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
        my $cmd = shift @cmds;
        local $_ = $cmd;

        system("$_");
		$self->rm_zero([qw( idx bbl mtc maf )]);

        /^\s*pdflatex\s+/ && ($i == 1) && do { 
            my @texindy = $blx->_cmds_texindy({ dir => $root });
            unshift @cmds, @texindy;
        };

        /^\s*bibtex\s+/  && do { 

			$self->rm_zero([qw( bbl )]);
			
			my @bbl = $blx->_find_([$root],[qw(bbl)]);

	        push @cmds, 
	           $blx->_cmd_pdflatex;

			if (@bbl) {
	            push @cmds, 
	                $blx->_cmd_pdflatex;
			}
        };

        $i++;

    }

    return $self;
};

1;
 
