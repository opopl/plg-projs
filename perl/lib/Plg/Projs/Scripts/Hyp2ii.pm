
package Plg::Projs::Scripts::Hyp2ii;

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use File::Slurp::Unicode;
use Base::Arg qw( hash_inject );
use FindBin qw($Bin $Script);
use Getopt::Long qw(GetOptions);

use Plg::Projs::Tex qw( texify );

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

    EXAMPLES
        $Script -i IFILE -o OFILE
    };

    print $s . "\n";

    return $self;   
}

sub process_input {
    my ($self) = @_;

    my $ifile = $self->{input};
    my $ofile = $self->{output};

	print Dumper($ifile) . "\n";

    my $tex = read_file $ifile;

    texify(\$tex,'hyp2ii');
	print Dumper($tex) . "\n";

    #write_file($ofile,$tex);

    return $self;   
}

sub run {
    my ($self) = @_;

    while(1){
        if ($self->{input}) {
            $self->process_input;
            last;
        }

        last;
    }

    return $self;
}

1;
 

