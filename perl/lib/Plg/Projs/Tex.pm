
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
    my ($ss, $cmd) = @_;

    my $s = ref $ss eq 'SCALAR' ? $$ss : $ss;

    $cmd ||= 'enquote';
    my $start = sprintf(q|\%s{|,$cmd);
    my $end   = q|}|;

    my @c  = split("" => $s);
    my %is = ( qq => 0, q => 0 );
    my @n;
    while (@c) {
        local $_ = shift @c;
        /"/ && do {
            $is{qq} ^= 1;

            push @n, $start if $is{qq};
            push @n, $end unless $is{qq};
            next;
        };

        push @n, $_;
    }

    $s = join("",@n);

    $$ss = $s if ref $ss eq 'SCALAR';

    return $s;
}

1;
 

