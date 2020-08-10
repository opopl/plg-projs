package Plg::Projs::Build::PdfLatex;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Path qw( mkpath );
use File::Copy qw( copy );

my $proj = shift @ARGV;

sub new
{
	my ($class, %opts) = @_;
	my $self = bless (\%opts, ref ($class) || $class);

	$self->init if $self->can('init');

	return $self;
}

sub init {
	my ($self) = @_;

	my $proj = shift @ARGV;
	my $tex_opts = [];

	push @$tex_opts, 
		'-file-line-error',
		'-interaction nonstopmode',
		qq{ -output-directory=./builds/$proj/b_pdflatex },
		;

	my $root = $self->{root};

	my $pdfout = $ENV{PDFOUT};
	my $h = {
		proj       => $proj,
		pdfout     => $pdfout,
		tex_exe    => 'pdflatex',
		tex_opts   => $tex_opts,
		outdir     => catfile(qw(builds),$proj,qw(b_pdflatex)),
		outdir_pdf => catfile($pdfout,$proj),
		bibfile    => catfile($root,qq{$proj.refs.bib}),
	};

	$h = { %$h,
		outdir_pdf_b =>  catfile($h->{outdir_pdf},qw(b_pdflatex))
	};

	my @k = keys %$h;

	for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

	return $self;
}

sub run {
	my ($self) = @_;

	my $proj = $self->{proj};

	my @dirids = qw( outdir outdir_pdf outdir_pdf_b );
	foreach my $dirid (@dirids) {
		my $dir = $self->{$dirid};
		mkpath $dir;
	}
	copy( $self->{bibfile} => $self->{outdir} );

	my $cmd_tex = join(" ", @$self{qw( tex_exe tex_opts )}, $proj );
	system($cmd_tex);
	chdir $self->{outdir};
	system(qq{ bibtex $proj } );
	system(qq{ makeindex $proj } );
	system($cmd_tex);
	system($cmd_tex);

	my $built_pdf = catfile($self->{outdir}, "$proj.pdf");

	if (! -e $built_pdf) {
		warn 'NO PDF FILE!' . "\n";
		return;
	}

	my @pdf_files = 
		catfile($self->{outdir_pdf_b},"$proj.pdf"),
		;

	foreach my $dest (@pdf_files) {
		copy($built_pdf, $dest);
	}

	return $self;
}

1;
