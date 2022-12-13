package Plg::Projs::Html::Pretty;

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

use XML::LibXML;
use XML::LibXML::PrettyPrint;


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
        cmd => 'pretty',
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

sub cmd_pretty {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $file = $ref->{file} || $self->{input};
    my $output = $ref->{output} || $self->{output};

    my $html = read_file $file;

    $XML::LibXML::skipXMLDeclaration =
        $ref->{libxml_skip_xml_decl} || $self->{libxml_skip_xml_decl};
    my $opts_prettyprint = $ref->{opts_prettyprint} || {};

    my $defs = {
        expand_entities => 0,
        load_ext_dtd    => 1,
        no_blanks       => 1,
        no_cdata        => 1,
        line_numbers    => 1,
    };

    my $parser = XML::LibXML->new(%$defs);

    my $string = $ref->{decode} ? unc_decode($html) : $html;
    my $inp = {
        string          => $string,
        recover         => 1,
        suppress_errors => 1,
    };
    my $dom = $parser->load_html($inp);
    my $node = $dom;

    #my @block = qw/table tables columns entry latex_table options/;
    my @block = qw//;
    my %cb = (
        compact =>  sub {
            my $node = shift;
            my $name = $node->nodeName;
            return 0 if grep { /^$name$/ } @block;
            return 1;
        },
    );
    my $pp = XML::LibXML::PrettyPrint->new(
        indent_string => "  ",
        element => {
            inline   => [qw/span/],
            block    => [@block],
            #compact  => [qw//,$cb{compact}],
            preserves_whitespace => [qw/pre/],
        },
        %$opts_prettyprint,
    );
    $pp->strip_whitespace($node);
    $pp->pretty_print($node);

    my $text = $dom->toStringHTML;
    write_file($output, $text);

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
            --input  -i  string    Input HTML file
            --output -o  string    output HTML file
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


