
package Plg::Projs::Html;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

use warnings;
use strict;

use Exporter ();
use base qw(Exporter);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA     = qw(Exporter);
@EXPORT  = qw( );
$VERSION = '0.01';

###export_vars_scalar
my @ex_vars_scalar=qw(
);
###export_vars_hash
my @ex_vars_hash=qw(
);
###export_vars_array
my @ex_vars_array=qw(
);

%EXPORT_TAGS = (
###export_funcs
    'funcs' => [qw( 
        html_pretty
    )],
    'vars'  => [ @ex_vars_scalar,@ex_vars_array,@ex_vars_hash ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );

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

sub html_pretty {
    my ($ref) = @_;
    $ref ||= {};

    my ($file, $html, $output) = @{$ref}{qw( file html output )};

    $html ||= read_file $file;
    my $html_string = ref $html eq 'SCALAR' ? $$html : $html;

    $XML::LibXML::skipXMLDeclaration = $ref->{libxml_skip_xml_decl};
    my $opts_prettyprint = $ref->{opts_prettyprint} || {};

    my $defs = {
        expand_entities => 0,
        load_ext_dtd    => 1,
        no_blanks       => 1,
        no_cdata        => 1,
        line_numbers    => 1,
    };

    my $parser = XML::LibXML->new(%$defs);

    my $string = $ref->{decode} ? unc_decode($html_string) : $html;
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
    write_file($output, $text) if $output;

    if (ref $html eq 'SCALAR') {
        $$html = $text;
    }

    return $text;
}


1;
 

