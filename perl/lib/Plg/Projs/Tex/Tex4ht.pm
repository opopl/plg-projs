
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
use Deep::Hash::Utils qw( deepvalue );
use Data::Dumper qw(Dumper);

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

    my $vars = $cnf->{vars} || {};
    my $content = $cnf->{content} || [];
    my ($open, $close) = qw( { } );

    foreach my $x (@$content) {
        local $_ = trim($x);

        /^\@\@(?<key>\w+)(|\{(?<path>.*)\})$/ && do {
            my ($key, $path) = @+{qw(key path)};

            my $entry = $cnf->{'@@' . $key };
            next unless $entry;

            my $type = $entry->{'@type'} || '';
            my $sprintf = $entry->{'@sprintf'};
###sprintf
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
               next;
            }

            my @path_a = split('\.', $path);
            my $wal = deepvalue($entry, @path_a );

###type_css
            if($type eq 'css'){
                my @css;
                if (ref $wal eq 'HASH') {
                    my @css;
                    my $indent_css = ' ' x 2;
                    my $indent_rule = ' ' x 4;

                    while(my($selector, $rule)=each %{$wal}){
                        next unless ref $rule eq 'HASH';
                        next unless keys %$rule;

                        my @rule_css;
                        while(my($k,$v)=each %{$rule}){
                          push @rule_css, $indent_rule . sprintf('%s : %s;', $k, $v);
                        }
                        push @css, $indent_css
                              . $selector . ' : ' . $open . "\n"
                              . join("\n" => @rule_css) . "\n"
                              . $indent_css . $close;
                    }
                    push @txt, sprintf('\Css{%s}',"\n" . join("\n" => @css) . "\n") if @css;
                }
                next;
            }

            unless(ref $wal){
                push @txt, varexp($wal, $vars);
            }elsif (ref $wal eq 'ARRAY') {
                foreach my $ww (@$wal) {
                    push @txt, varexp($ww, $vars);
                }
            }

            next;
        };

        push @txt, $_;
    }

    return @txt;

}

sub varexp {
    my ($val, $vars) = @_;
    $vars ||= {};

    local $_ = $val;
    s|\$var\{(\w+)\}|$vars->{$1} // ''|ge;

    return $_;
}

1;


