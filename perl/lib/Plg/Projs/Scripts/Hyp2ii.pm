
package Plg::Projs::Scripts::Hyp2ii;

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use File::Slurp::Unicode;
use Base::Arg qw( hash_inject );
use FindBin qw($Bin $Script);
use Getopt::Long qw(GetOptions);

use Plg::Projs::Tex qw( texify );
use Plg::Projs::Prj;
use Cwd qw(getcwd);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}


sub init {
    my ($self) = @_;
    
    $self->get_opt;
    
    my $h = {};
        
    hash_inject($self, $h);
    return $self;
}

      
sub get_opt {
    my ($self) = @_;
    
    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));
    
    my (@optstr, %opt);
    @optstr = ( 
        "input|i=s",
        "output|o=s",
        "proj|p=s",
        "sec|s=s",
    );
    
    unless( @ARGV ){ 
        $self->print_help;
        exit 0;
    }else{
        GetOptions(\%opt,@optstr);
        $self->{opt} = \%opt;
    }

    foreach my $k (keys %opt) {
        $self->{$k} = $opt{$k};
    }

    return $self;   
}

sub print_help {
    my ($self) = @_;

    my $s = qq{

    USAGE
        $Script OPTIONS
    OPTIONS
        -o --out OUTPUT  (FILE)
        -i --input INPUT (FILE)
        -s --sec SEC
        -p --proj PROJ

    EXAMPLES
        $Script -i IFILE -o OFILE
    };

    print $s . "\n";

    return $self;   
}

sub process_input {
    my ($self) = @_;

    my ($ifile, $sec, $proj) = @{$self}{qw( input sec proj )};
    my $ofile = $self->{output};

    my $root = getcwd();
    my $prj = Plg::Projs::Prj->new(root => $root);

    unless ($ifile) {
       if ($proj && $sec) {
           my $sdata = $prj->_sec_data({ proj => $proj, sec => $sec });
           $ifile = $sdata->{file};
       }
    }

    unless ($ifile && -f $ifile){
       warn qq{no input file! abort} . "\n";
       return $self;
    }

    my $tex = read_file $ifile;

    texify(\$tex,'hyp2ii');
    if ($ofile) {
        write_file($ofile,$tex);
    }else{
        print qq{$tex} . "\n";
    }
    return $self;   
}

sub run {
    my ($self) = @_;

    while(1){
      $self->process_input;

      last;
    }

    return $self;
}

1;
 

