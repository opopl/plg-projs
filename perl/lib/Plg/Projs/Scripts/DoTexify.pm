
package Plg::Projs::Scripts::DoTexify;

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Plg::Projs::Tex qw( texify );

use File::Slurp::Unicode;
use Base::Arg qw( hash_inject );
use FindBin qw($Bin $Script);
use Getopt::Long qw(GetOptions);

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
    
    my $h = {
    };
        
    hash_inject($self, $h);
    return $self;
}

      
sub get_opt {
    my ($self) = @_;
    
    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));
    
    my (@optstr, %opt);
    @optstr=( 
        "start|s=s",
        "end|e=s",
        "file|f=s",
        "cmd|c=s",
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
        -c --cmd COMMAND

        -f --file FILE
        -s --start START position (line number)
        -e --end END position (line number)

    EXAMPLES
        $Script -c rpl_quotes -f FILE 
        $Script -c rpl_quotes --file FILE

        $Script -c rpl_quotes -f FILE -s START -e END

    };

    print $s . "\n";

    return $self;   
}

sub process_file {
    my ($self) = @_;

    my $file = $self->{file};
    my $cmd  = $self->{cmd};

    my $tex  = read_file $file;

    my @a = @{$self}{qw( start end )};
    texify(\$tex,$cmd,@a);

    write_file($file,$tex);

    return $self;   
}

sub run {
    my ($self) = @_;

    while(1){
        if ($self->{file}) {
            $self->process_file;
            last;
        }

        last;
    }

    return $self;
}

1;
 

