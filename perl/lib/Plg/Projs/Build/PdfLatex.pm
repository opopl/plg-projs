package Plg::Projs::Build::PdfLatex;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Path qw( mkpath );
use File::Copy qw( copy );
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
use File::Slurp::Unicode;
use Data::Dumper qw(Dumper);

#use open IO => ":raw:utf8"; 
#docstore.mik.ua/orelly/perl4/cook/ch08_20.htm

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
    my $tex_opts_a = [];

    print $proj . "\n";

    push @$tex_opts_a, 
        '-file-line-error',
        '-interaction nonstopmode',
        qq{ -output-directory=./builds/$proj/b_pdflatex },
        ;

    my $tex_opts = join(" ", @$tex_opts_a);

    my $root = $self->{root};

    my $pdfout = $ENV{PDFOUT};
    my $h = {
        proj       => $proj,
        pdfout     => $pdfout,
        tex_exe    => 'pdflatex',
        tex_opts   => $tex_opts,
        tex_opts_a => $tex_opts_a,
        out_dir     => catfile($root, qw(builds),$proj,qw(b_pdflatex)),
        out_dir_pdf => catfile($pdfout,$proj),
        bib_file    => catfile($root,qq{$proj.refs.bib}),
    };

    $h = { %$h,
        out_dir_pdf_b => catfile($h->{out_dir_pdf}, qw(b_pdflatex) )
    };

    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

    return $self;
}

sub run {
    my ($self) = @_;

    my $proj = $self->{proj};
    my $root = $self->{root};

    my @dirids = qw( out_dir out_dir_pdf out_dir_pdf_b );
    foreach my $dirid (@dirids) {
        my $dir = $self->{$dirid};
        mkpath $dir;
    }
    my $projbib = catfile( $self->{out_dir}, "$proj.bib");
    copy( $self->{bib_file}, $projbib ) 
        if -e $self->{bib_file};

    my $log_dir = catfile(qw(log txt),$proj);
    mkpath $log_dir;

    #my $out_file = catfile($log_dir, qq{pdflatex.txt });
    #print $out_file . "\n";
    #my @redir = sprintf('>%s 2>&1 ',$out_file);
    #my $cmd_tex = join(" ", @$self{qw( tex_exe tex_opts )}, $proj, @redir  );
    
    my $cmd_tex = join(" ", @$self{qw( tex_exe tex_opts )}, $proj );
    system($cmd_tex);

    chdir $self->{out_dir};
    system(qq{ bibtex $proj } ) if -e $projbib;
    #system(qq{ makeindex $proj } );
    #system(qq{ texindy -L russian -C utf8 -M latin-alph.xdy $proj.idx });
    system(qq{ texindy -L russian -C utf8 $proj.idx });
#\makeindex [options = -L russian -C utf8 -M latin-alph.xdy]

    my $ind_file = catfile("$proj.ind");

    my $level = 1;

    if (-e $ind_file) {
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
        #print Dumper(\%ind_items) . "\n";

    }
    #return ;
    chdir $self->{root};

    system($cmd_tex);
    system($cmd_tex);

    my $built_pdf = catfile($self->{out_dir}, "$proj.pdf");

    if (! -e $built_pdf) {
        warn 'NO PDF FILE!' . "\n";
        return;
    }

    my @pdf_files = 
        catfile($self->{out_dir_pdf_b},"$proj.pdf"),
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
