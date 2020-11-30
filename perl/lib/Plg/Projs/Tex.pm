
package Plg::Projs::Tex;

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use Base::String qw(
	str_split
);

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
    my ($ss,$cmd,$s_start,$s_end) = @_;

    $cmd ||= 'rpl_quotes';
    my @cmds; push @cmds, str_split($cmd);

    $s_start //= $l_start;
    $s_end //= $l_end;

    _str($ss,$s_start,$s_end);

    _do(\@cmds);

    _back($ss);
    return $s_full;
}

sub _acts {
    my @a;
    push @a,
        'rpl_quotes',
        'rpl_dashes',
        'rpl_special',
        ;
    return [@a];
}

sub _do {
    my ($acts) = @_;
    $acts ||= _acts();

    foreach my $x (@$acts) {
        eval $x .'()';
    }
    #q2quotes();
    #rpl_dashes();
    #rpl_special();

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

    @center = split("\n",$s);
    @split = (@before,@center,@after);

    $s_full = join("\n",@split) . "\n";

    if (ref $ss eq 'SCALAR'){
        $$ss = $s_full;

    } elsif (ref $ss eq 'ARRAY'){
        $ss = [ @split ];
    }
}

sub rpl_quotes {
    my ($cmd) = @_;

    #$cmd ||= 'enquote';
    $cmd ||= 'zqq';
    my $start = sprintf(q|\%s{|,$cmd);
    my $end   = q|}|;

    my @c  = split("" => $s);
    my %is = ( qq => 0, q => 0 );
    my @n;

	my $push_qq = sub {
      $is{qq} ^= 1;

      push @n, $start if $is{qq};
      push @n, $end unless $is{qq};
	};

	# opening/closing quotes
	my %br = (
		q{“} => q{”}
	);

	C: while (@c) {
        local $_ = shift @c;
		my $c = $_;

        /"/ && do {
			$push_qq->();
            next;
        };

		( grep { /^\Q$c\E$/ } keys %br ) && do {
      		push @n, $start;
			next;
		};
		( grep { /^\Q$c\E$/ } values %br ) && do {
      		push @n, $end;
			next;
		};

        push @n, $_;
    }

    $s = join("",@n);
}

sub rpl_verbs {
    local $_ = $s;

    s/([^\\]+)\\(\w+)\b/$1\\verb|\\$2|/g;

    $s = $_;
}

sub rpl_special {
    local $_ = $s;

    s/_/\\_/g;
    s/%/\\%/g;

    $s = $_;
}

sub rpl_dashes {
    local $_ = $s;

    s/\s+(-|–)\s+/ \\dshM /g;
    
    $s = $_;
}

1;
 

