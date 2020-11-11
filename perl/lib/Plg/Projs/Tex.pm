
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
        texify
    )],
    'vars'  => [ @ex_vars_scalar,@ex_vars_array,@ex_vars_hash ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );

sub texify {
    my ($ss) = @_;

    my $s = _str($ss);

    q2quotes(\$s);
    rpl_dashes(\$s);

    $$ss = $s if ref $ss eq 'SCALAR';
    return $s;
}

sub _back {
    my ($ss, $s) = @_;

    if (ref $ss eq 'SCALAR'){
        $$ss = $s;
    } elsif (ref $ss eq 'ARRAY'){
        $ss = [ split("\n",$s) ];
    }
}

sub _str {
    my ($ss) = @_;

    my $s;
    if (ref $ss eq 'SCALAR'){ 
        $s = $$ss;
    } elsif (ref $ss eq 'ARRAY'){ 
        $s = join("\n",@$ss);
    }
    elsif (! ref $ss){ 
        $s = $ss;
    }
    return $s;
}

sub q2quotes {
    my ($ss, $cmd) = @_;

    my $s = _str($ss);

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

    _back($ss, $s);
    return $s;
}

sub rpl_dashes {
    my ($ss) = @_;

    local $_ = _str($ss);
	s/\s+(-|–)\s+/ \\dshM /g;

    _back($ss, $_);
    return $_;
}

1;
 

