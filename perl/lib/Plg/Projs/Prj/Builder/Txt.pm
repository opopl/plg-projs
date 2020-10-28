
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
    
    my $decs = $bld->_val_('decs');
    my %decs = map { $_ => 1 } str_split_sn($decs);

    my $add = 1;
    my $if  = 0;

    my @expand;
    while(@$txt_lines){
        local $_ = shift @$txt_lines;

        #my @a = split("",$_);
        #my $s='';
        #my $r = qr/\@var\{(\w+)\}/;
        #while(@a){
            #$s .= shift @a;
            #my ($var) = ($s =~ /$r/);
            #next unless defined $var;
            #my $val = $bld->_bld_var($var);
            #$s =~ s/$r/$val/g; 
        #}
        #$_ = $s;

        s/\@var\{(\w+)\}/$bld->_bld_var($1)/ge; 
        s/\@env\{(\w+)\}/$bld->_bld_env($1)/ge; 

        /\@ifdec\{([^{}]+)\}/ && do {
            my $df = $1;

            $add = 0 unless $decs{$df};
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
 

