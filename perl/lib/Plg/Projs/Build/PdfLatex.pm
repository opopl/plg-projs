
package Plg::Projs::Build::PdfLatex;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Path qw( mkpath );
use File::Copy qw( copy );
use FindBin qw($Bin $Script);

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
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

      
sub get_opt {
    my ($self) = @_;

    my (%opt, @optstr, $cmdline);
    
    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));
    
    @optstr = ( 
        "cmd|c=s",
    );

    $self->{root}    = $Bin;

    unless( @ARGV ){ 
        $self->dhelp;
        exit 0;
    }else{
        $self->{proj}    = shift @ARGV;
        $self->{root_id} = shift @ARGV;

        $cmdline = join(' ',@ARGV);
        GetOptions(\%opt,@optstr);
        $self->{opt} = {%opt};
    }

    return $self;    
}

sub dhelp {
    my ($self) = @_;

    my $s = qq{

    USAGE
        $Script PROJ ROOT_ID OPTIONS
    OPTIONS
        --cmd -c CMD 

    EXAMPLES
        $Script aa texdocs
        $Script aa texdocs -c copy_to_builds
    };

    print $s . "\n";

    return $self;    
}

sub init {
    my ($self) = @_;

    $self->get_opt;

    my $tex_opts_a = [];

    my $root    = $self->{root};
    my $root_id = $self->{root_id};
    my $proj    = $self->{proj};

    my $pdfout = $ENV{PDFOUT};

    my @build_dir_a = ( "builds", $proj, "b_pdflatex" );

    my $h = {
        proj           => $proj,
        pdfout         => $pdfout,
        tex_exe        => 'pdflatex',
        build_dir_unix => join("/",@build_dir_a),
        build_dir      => catfile($root, @build_dir_a),
        bib_file       => catfile($root, qq{$proj.refs.bib}),
        out_dir_pdf    => catfile($pdfout, $root_id),
        dbfile         => catfile($root,'projs.sqlite'),

    };

    push @$tex_opts_a, 
        '-file-line-error',
        '-interaction nonstopmode',
        qq{ -output-directory=./ } . $h->{build_dir_unix},
        ;

    my $tex_opts = join(" ", @$tex_opts_a);

    $h = { %$h,
        src_dir       => catfile($h->{build_dir},qw( .. src)),
        tex_opts      => $tex_opts,
        tex_opts_a    => $tex_opts_a,
        out_dir_pdf_b => catfile($h->{out_dir_pdf}, qw(b_pdflatex) )
    };

    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

    return $self;
}

sub process_ind_file {
    my ($self, $ind_file, $level) = @_;

    unless (-e $ind_file){
        return $self;
    }

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

   return $self;
}

sub _sec_file {
    my ($self, $sec) = @_;

    catfile($self->{root},join("." => ( $self->{proj}, $sec, 'tex' )) );


}

sub join_lines {
    my ($self, $sec) = @_;

    $sec ||= '_main_';

    my $proj = $self->{proj};
    chdir $self->{root};

    my $jfile = catfile($self->{src_dir},$proj . '.tex');

    my  $sf      = {};
    $sf->{$sec} = $self->_sec_file($sec);
    my $f       = $sf->{$sec};

    if (!-e $f){ return (); }

    my @lines;
    my @flines = read_file $f;

    my $pats = {
         'ii'    => '^\s*\\ii{(.+)}.*$',
         'iifig' => '^\s*\\iifig{(.+)}.*$',
         'input' => '^\s*\\input{(.*)}.*$',
    };

    my $delim = '%' x 50;  
 
    foreach(@flines) {
        chomp;

        m/$pats->{ii}/ && do {
            my $ii_sec   = $1;
            my @ii_lines = $self->join_lines($ii_sec);

            push @lines, 
                $delim,
                '%% ' . $_,
                $delim,
                @ii_lines
            ;
            next;
        };

        m/$pats->{iifig}/ && do {
            my $fig_sec   = 'fig.' . $1;
            my @fig_lines = $self->join_lines($fig_sec);

            push @lines, 
                $delim,
                '%% ' . $_,
                $delim,
                @fig_lines
            ;

            next;
        };

        push @lines, $_;
    }

    if ($sec eq '_main') {
        write_file($jfile,join("\n",@lines) . "\n");
    }

    return @lines;
}

sub cmd_insert_img {
    my ($self) = @_;

    $self
        ->cmd_copy_to_builds
        ;

    foreach my $file (@{ $self->{files} || [] }) {
        my $path = catfile($self->{src_dir},$file);
        next unless -e $path;
        next unless ($file =~ /\.tex$/);

        print $path . "\n";
    }

    return $self;
}

sub cmd_copy_to_builds {
    my ($self) = @_;

    my $proj = $self->{proj};
    my $root = $self->{root};

    my $dbfile = $self->{dbfile};

    my $dbh = dbi_connect({
        dbfile => $self->{dbfile},
    });

    my $ref = {
        dbh     => $dbh,
        t       => 'projs',
        f       => [qw(file)],
        p       => [$proj],
        cond    => qq{ WHERE proj = ? },
    };
    $self->{files} = dbh_select_as_list($ref);
    mkpath $self->{src_dir};

    foreach my $file (@{ $self->{files} || [] }) {
        my $path = catfile($root,$file);
        copy($path, $self->{src_dir} );
    }

    return $self;
}

sub run_cmd {
    my ($self) = @_;

    if (my $cmd = $self->{opt}->{cmd}) {
        my $sub = 'cmd_'.$cmd;
        if ($self->can($sub)) {
            $self->$sub;
        }else{
            warn "No command defined: " . $cmd . "\n";
            exit 1;
        }
        exit 0;
    }

    return $self;
}

sub run {
    my ($self) = @_;

    $self->run_cmd;

    my $proj = $self->{proj};
    my $root = $self->{root};

    my @dirids = qw( out_dir out_dir_pdf out_dir_pdf_b );
    foreach my $dirid (@dirids) {
        my $dir = $self->{$dirid};
        mkpath $dir;
    }
    my $proj_bib = catfile( $self->{out_dir}, "$proj.bib");
    copy( $self->{bib_file}, $proj_bib ) 
        if -e $self->{bib_file};

    my $cmd_tex = join(" ", @$self{qw( tex_exe tex_opts )}, $proj );
    system($cmd_tex);

    chdir $self->{out_dir};
    
    system(qq{ bibtex $proj } ) if -e $proj_bib;
    system(qq{ texindy -L russian -C utf8 $proj.idx });

    my $ind_file = catfile("$proj.ind");
    #$self->process_ind_file($ind_file, 1);;

    #return ;
    chdir $self->{root};

    system($cmd_tex);
    system($cmd_tex);

    my $built_pdf = catfile($self->{out_dir}, "$proj.pdf");

    if (! -e $built_pdf) {
        warn 'NO PDF FILE!' . "\n";
        return;
    }

    my @pdf_files;
    push @pdf_files, 
        catfile($self->{out_dir_pdf_b},"$proj.pdf"),
        catfile($self->{out_dir_pdf},"$proj.pdf"),
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
