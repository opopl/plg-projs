
package Plg::Projs::Tex;

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

binmode STDOUT,':encoding(utf8)';

use Exporter ();
use base qw(Exporter);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA     = qw(Exporter);
@EXPORT  = qw( );
$VERSION = '0.01';

###our
our($l_start,$l_end);

our(@split,@before,@after,@center);

our ($s, $s_full);

my @ex_vars_scalar=qw(
);
my @ex_vars_hash=qw(
);
my @ex_vars_array=qw(
);

%EXPORT_TAGS = (
    'funcs' => [qw( 
        q2quotes
        texify
    )],
    'vars'  => [ @ex_vars_scalar,@ex_vars_array,@ex_vars_hash ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );

sub texify {
    my ($ss,$s_start,$s_end) = @_;

    $s_start //= $l_start;
    $s_end //= $l_end;

    _str($ss,$s_start,$s_end);

	_do();

    _back($ss);
    return $s_full;
}

sub _do {
    local $_ = $s;

    q2quotes();
    rpl_dashes();
    rpl_underscore();

    $s = $_;
}

sub _str {
    my ($ss,$s_start,$s_end) = @_;

    $s_start //= $l_start;
    $s_end //= $l_end;

    if (ref $ss eq 'SCALAR'){ 
        $s = $$ss;
        @split = split("\n" => $s);

    } elsif (ref $ss eq 'ARRAY'){ 
        @split = @$ss;
        $s = join("\n",@split);
    }
    elsif (! ref $ss){ 
        $s = $ss;
        @split = split("\n" => $s);
    }

    if (defined $s_start && defined $s_end) {
        my $i = 1;
        for(@split){
            chomp;

            do { push @before, $_; $i++; next; } if $i < $s_start;
            do { push @after, $_; $i++; next; } if $i > $s_end;

            push @center,$_;
            $i++;
        }

    }else{
        @center = @split;
    }
    $s = join("\n",@center);

}

sub strip_comments {
    my ($ss, $s) = @_;

    #my $s = _str($ss);

    _back($ss, $s);
    return $s;
}

sub _back {
    my ($ss) = @_;

    @split = (@before,@center,@after);
    $s_full = join("\n",@split) . "\n";

    if (ref $ss eq 'SCALAR'){
        $$ss = $s_full;

    } elsif (ref $ss eq 'ARRAY'){
        $ss = [ @split ];
    }
}

sub q2quotes {
    my ($ss, $cmd) = @_;

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
    @center = split("\n",$s);
}

sub rpl_underscore {
    s/\b_\b/\_/g;
}

sub rpl_dashes {
    s/\s+(-|–)\s+/ \\dshM /g;

}

1;
 

