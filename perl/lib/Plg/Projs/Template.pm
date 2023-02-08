
package Plg::Projs::Template;

use utf8;
use strict;
use warnings;
binmode STDOUT,':encoding(utf8)';

use Exporter ();
use base qw(Exporter);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA     = qw(Exporter);
@EXPORT  = qw( );
$VERSION = '0.01';

###export_vars_scalar
my @ex_vars_scalar=qw(
    $tm_dir
    $tm_file_page
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
        tmpl_render
    )],
    'vars'  => [ @ex_vars_scalar,@ex_vars_array,@ex_vars_hash ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );

use Text::Template;
use File::Spec::Functions qw(catfile);

our $tm_dir         = catfile($ENV{PLG}, qw( projs templates perl ));
our $tm_file_page   = catfile($tm_dir, qw( html page.phtml ));

sub tmpl_render {
    my ($tmpl, $ref) = @_;
    $ref ||= {};
    my $data = $ref->{data} || {};

    my $tfile = catfile($tm_dir, qw(html), $tmpl);

    my $body = Text::Template
        ->new(SOURCE => $tfile)
        ->fill_in(HASH => $data);

    my $page_vars = {
        body => $body,
    };

    my $html_full = Text::Template
        ->new(SOURCE => $tm_file_page)
        ->fill_in(HASH => $page_vars);

    return $html_full;
}

1;


