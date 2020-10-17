
package Plg::Projs::Prj::Builder::Txt;

use utf8;
binmode STDOUT,':encoding(utf8)';

use strict;
use warnings;
use Data::Dumper qw(Dumper);

use Base::String qw(
    str_split_sn
);

=head3 _txt_expand

    # Update SCALAR
    $bld->_txt_expand({ txt_ref => \$txt_ref });

    # Update ARRAY
    $bld->_txt_expand({ txt_lines => \@txt_lines });

=cut

sub _txt_expand {
    my ($bld, $ref) = @_;

    my $txt_lines = $ref->{txt_lines} || [];
    my $txt_ref   = $ref->{txt_ref};

    @$txt_lines = split("\n",$$txt_ref) if $txt_ref;
    
    my $defs = $bld->_val_('defs');
    my %defs = map { $_ => 1 } str_split_sn($defs);

    my $add = 1;
    my $if  = 0;

    #my $val = $bld->_val_('vars pagestyle') || '';
    #print Dumper($val) . "\n";
    #exit 1;

    my @expand;
    while(@$txt_lines){
        local $_ = shift @$txt_lines;

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
    @$txt_lines = @expand;

    $$txt_ref = join("\n",@$txt_lines) if $txt_ref;

    return $bld;
}

1;
 

