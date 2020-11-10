
package Plg::Projs::Tex;

use strict;
use warnings;
use utf8;

binmode STDOUT,':encoding(utf8)';

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
		q2quotes
	)],
	'vars'  => [ @ex_vars_scalar,@ex_vars_array,@ex_vars_hash ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );

sub q2quotes {
	my ($s_ref) = @_;
	my $s = $$s_ref;

    my @c = split("",$s);
    my %is = ( qq => 0, q => 0 ) ;
    my @n;
    while (@c) {
        local $_ = shift @c;
        /"/ && do {
            $is{qq} ^= 1;
        };

        if ($is{qq}) {
            # body...
        }
        push @n, $_;
    }

	$$s_ref = join("",@n);
}

1;
 

