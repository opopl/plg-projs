package Plg::Projs::Html::Pretty;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

use Data::Dumper qw(Dumper);
use FindBin qw($Bin $Script);
use YAML qw(LoadFile);
use Getopt::Long qw(GetOptions);

use Base::Arg qw(
    hash_inject
    hash_update

    dict_update
);

use base qw(
    Base::Cmd
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

    my $h = {
        cmd => 'load_file',
    };

    hash_inject($self, $h);

    $self
        ->get_opt
        ->get_yaml
        ;

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

sub print_help {
    my ($self) = @_;

    my $pack = __PACKAGE__;
    print qq{
        PACKAGES:
            $pack
        LOCATION:
            $0
        OPTIONS:
            --f_yaml -y string YAML control file
        USAGE:
            PROCESS HTML FILE:
                perl $Script -i INPUT -o OUTPUT -y YFILE
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

    hash_update($self, \%opt);

    return $self;
}

sub run {
    my ($self) = @_;

    $self
       ->run_cmd;

    return $self;
}


1;


