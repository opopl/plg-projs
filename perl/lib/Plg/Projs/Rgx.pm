
package Plg::Projs::Rgx;

use strict;
use warnings;

use Exporter ();
use base qw(Exporter);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Data::Dumper qw(Dumper);

@ISA     = qw(Exporter);
@EXPORT  = qw( );
$VERSION = '0.01';

###export_vars_scalar
my @ex_vars_scalar=qw(
);
###export_vars_hash
my @ex_vars_hash=qw(
   %rgx_map
);
###export_vars_array
my @ex_vars_array=qw(
);

%EXPORT_TAGS = (
###export_funcs
    'funcs' => [qw(
        rgx_match
    )],
    'vars'  => [ @ex_vars_scalar,@ex_vars_array,@ex_vars_hash ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );

our %rgx_map = (
   jnd => {
     macros => {
       igg => qr/\@igg\{([^{}]*)\}(?:\{([^{}]*)\}|)/,
     }
   },
   builder => {
     patch_bare => qr/^patch(?<sep>[\/%\._\@]+|)$/,
     patch_key => qr/^patch(?<sep>[\/%\._\@]+|)(?<key>.*)$/,
     target => {
       buf => qr/^_buf\.(?<section>(?<day>\d+)_(?<month>\d+)_(?<year>\d+)\.(\S+))$/,
     }
   }
);

sub rgx_match {
    my ($pattern, $string, $flags, $index) = @_;

    local $_ = $string;
    $flags ||= '';

    my ($result, @group, $match);
    eval sprintf('@group = ( m/%s/%s ); $match = $& if @group; ', $pattern, $flags);
    return unless @group;

    #print Dumper(\@group) . "\n";
    #print Dumper($match) . "\n";

    unless($index){
      $result = $match;
    }elsif($index =~ /^\d+$/){
      $result = $index > 0 ? $group[$index-1] : $match;
    }

    return $result;
}

1;

