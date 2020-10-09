
package Plg::Projs::Prj::Builder::Txt;

use utf8;
binmode STDOUT,':encoding(utf8)';

use strict;
use warnings;

use Base::String qw(
    str_split_sn
);

sub _txt_expand {
    my ($bld, $ref) = @_;

    my $txt = $ref->{txt} || [];
    
    my $defs = $bld->_val_('defs');
    my %defs = map { $_ => 1 } str_split_sn($defs);

    my $add = 1;
    my $if  = 0;

    my @expand;
    while(@$txt){
        local $_ = shift @$txt;

        s/\@var\{(\w+)\}/$bld->_bld_var($1)/ge; 
        s/\@env\{(\w+)\}/$bld->_bld_env($1)/ge; 

        /\@ifdef\{([^{}]+)\}/ && do {
            my $df = $1;

            $add = 0 unless $defs{$df};
            $if++;
            next;
        };

        /\@fi/ && do {
            $add = 1;
            $if--;
            next;
        };

        push @expand, $_ if $add;
    }
    $txt = \@expand;

    return $bld;
}

1;
 

