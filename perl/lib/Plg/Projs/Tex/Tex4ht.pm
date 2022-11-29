
package Plg::Projs::Tex::Tex4ht;

use strict;
use warnings;
use utf8;


binmode STDOUT,':encoding(utf8)';

use Exporter ();
use base qw(Exporter);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use String::Util qw(trim);
use Base::List qw(uniq);

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
        ht_cnf2txt
    )],
    'vars'  => [ @ex_vars_scalar,@ex_vars_array,@ex_vars_hash ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );

sub ht_cnf2txt {
    my ($cnf) = @_;
    $cnf ||= {};

    my @txt;
    my @preamble_line;

    my $content = $cnf->{content} || [];

    foreach my $x (@$content) {
        local $_ = trim($x);
        next unless length;

        /^\@\@(?<key>\w+)(|\{(?<path>.*)\})$/ && do { 
            my ($key, $path) = @+{qw(key path)};

            my $w = $cnf->{'@@' . $key };
            next unless $w;

            my $sprintf = $w->{'@sprintf'};
            if ($sprintf) {
               my ($string, $bare) = @{$sprintf}{qw( string values )};
               my @values;

               if ($string && $bare && ref $bare eq 'ARRAY') {
                   foreach my $val (@$bare) {
                     unless (ref $val) {
                        push @values, $val;
                     }elsif(ref $val eq 'HASH'){
                        my $join = $val->{join};
                        if ($join && ref $join eq 'HASH') {
                           my ($list, $sep) = @{$join}{qw( list sep )};
                           if ($list && ref $list eq 'ARRAY' && $sep) {
                              push @values, join($sep, @$list);
                           }
                        }
                     }
                   }
                   push @txt, sprintf($string, @values);
               }
            }
        };
    }
    $DB::single = 1;

    return @txt;

}

1;
 

