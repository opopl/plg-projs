
package Plg::Projs::Sec::Saved;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

use Data::Dumper qw(Dumper);
use FindBin qw($Bin $Script);
use YAML qw(LoadFile);
use Getopt::Long qw(GetOptions);

use Base::Enc qw( unc_decode );
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);
use File::Copy qw(copy);
use File::Slurp::Unicode;
use Cwd qw(getcwd);

use XML::LibXML;
use XML::LibXML::PrettyPrint;

use Plg::Projs::Html qw(
    html_pretty
);


use Base::Arg qw(
    hash_inject
    hash_update

    dict_update
);

use base qw(
    Base::Cmd
    Plg::Projs::Prj
);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub init {
    my ($self) = @_;

	my $root = getcwd();
    my $h = {
        cmd => 'run',
        root     => $root,
        root_id  => basename($root),
    };

    hash_inject($self, $h);

    $self
        ->get_opt
        ->get_yaml
        ->Plg::Projs::Prj::init()
        ;
	$DB::single = 1;

    return $self;
}

sub get_yaml {
    my ($self) = @_;

    my $f_yaml = $self->{f_yaml};
    return $self unless $f_yaml;

    my $data = LoadFile($f_yaml);

    foreach my $k (keys %$data) {
        $self->{$k} = $$data{$k};
    }

    return $self;
}

sub cmd_pretty {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $file = $ref->{file} || $self->{input};
    my $output = $ref->{output} || $self->{output};

    html_pretty({ 
       file   => $file,
       output => $output,
    });

    return $self;
}

sub print_help {
    my ($self) = @_;

    my $pack = __PACKAGE__;
    print qq{
        PACKAGES:
            $pack
        LOCATION:
            $0
        OPTIONS:
            --f_yaml -y  string    YAML control file
            --sec    -s  string    section
            --proj   -p  string    project name
        USAGE:
            PROCESS HTML FILE:
                perl $Script -p PROJ -s SEC -y YFILE
    } . "\n";
    exit 0;

    return $self;
}

sub get_opt {
    my ($self) = @_;

    return $self if $self->{skip_get_opt};

    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));

    my (@optstr, %opt);

    @optstr = (
        "f_yaml|y=s",
        "sec|s=s",
        "proj|p=s",
    );

    unless( @ARGV ){
        $self->print_help;
        exit 0;
    }else{
        GetOptions(\%opt,@optstr);
        $self->{opt} = \%opt;
    }

    hash_update($self, \%opt);

    return $self;
}

sub cmd_run {
    my ($self) = @_;

	#my @secs = $self->_secs_select


    return $self;
}

sub main {
    my ($self) = @_;

    $self->run_cmd;

    return $self;
}

1;
 

