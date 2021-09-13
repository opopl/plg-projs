
package Plg::Projs::Regex;

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
   %regex 
);
###export_vars_array
my @ex_vars_array=qw(
);

%EXPORT_TAGS = (
###export_funcs
    'funcs' => [qw( 
        match
    )],
    'vars'  => [ @ex_vars_scalar,@ex_vars_array,@ex_vars_hash ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );

our %regex = (
   jnd => { 
     macros => {
       igg => qr/\@igg\{([^{}]*)\}(?:\{([^{}]*)\}|)/,
     }
   }
);

sub match {
    my ($pattern, $string, $flags, $index) = @_;

    local $_ = $string;
    $flags ||= '';

    my ($result, @group, $match);
    eval sprintf('@group = ( m/%s/%s ); $match = $&; ',$pattern,$flags);

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

