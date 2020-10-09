
package Plg::Projs::Prj::Builder::Trg;

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Base::XML::Dict qw(xml2dict);

use Deep::Hash::Utils qw(deepvalue);

use Base::Arg qw(
    hash_inject
    hash_apply
);

use Base::String qw(
    str_split
);

use Base::XML qw(
    node_to_pl
);

use File::Spec::Functions qw(catfile);

use XML::LibXML;
use XML::LibXML::Cache;
use XML::Simple qw(XMLin XMLout);

use base qw(
    Plg::Projs::Prj::Builder::Trg::usual
);

sub inj_targets {
    my ($bld) = @_;

    foreach my $trg ($bld->_trg_list) {
        my $sub = 'trg_inj_' . $trg;
        if ($bld->can($sub)) {
            $bld->$sub;
        }
    }
    return $bld;
}

sub _trg_list {
    my ($bld) = @_;

    @{ $bld->{trg_list} || [] };
}

sub trg_inject {
    my ($bld, $trg, $hash ) = @_;

    hash_inject($bld, { targets => { $trg => $hash }} );

    return $bld;

}

sub trg_apply {
    my ($bld, $target) = @_;

    $target //= $bld->{target};

    my $ht = $bld->_val_('targets', $target);
    hash_apply($bld, $ht);

    #if ($target eq 'core') {
        #print Dumper($bld->_val_(' opts_maker sections include')) . "\n";
        #exit;
    #}

    return $bld;
}

sub _trg_dom {
    my ($bld, $ref) = @_;

    $ref ||={};
    my $target = $bld->_opt_($ref,'target');

    my $dom = $bld->_val_('dom_trg ' . $target);

    unless ($dom) {
        my $xfile = $ref->{xfile} || $bld->_trg_xfile($target);
        return unless (-e $xfile);

        my $cache = XML::LibXML::Cache->new;
        $dom = $cache->parse_file($xfile);

        $bld->{dom_trg}->{$target} = $dom;
    }

    return $dom;

}

sub _trg_dom_find {
    my ($bld, $target) = @_;

    $target //= $bld->{target};
    my $dom = $bld->_trg_dom($target);

    my $data;
    return $data;

}

sub _trg_data {
    my ($bld, $ref) = @_;

    $ref ||= {};

    my $dom = $bld->_trg_dom($ref);
    return unless $dom;

    my $pl = xml2dict($dom, attr => '', array => [qw( scts )] );

    my $h_bld = $pl->{bld};

    return $h_bld;
}

sub xml_load_core {
    my ($bld, $ref) = @_;

    $ref ||= {};
    my $target = $bld->_opt_($ref,'target');

    return $bld;
}

sub trg_load_xml {
    my ($bld, $ref) = @_;

    $ref ||= {};
    my $target = $bld->_opt_($ref,'target');

    my $h_bld = $bld->_trg_data($ref);
    return $bld unless $h_bld;

    my $ht = $bld->_val_('targets',$target) || {};

    hash_apply($ht, $h_bld);

    $bld->{'targets'}->{$target} = $ht;


    return $bld;
}

sub _trg_xfile {
    my ($bld, $target) = @_;

    $target //= $bld->{target};

    my ($proj, $root) = @$bld{qw(proj root)};
    my $xfile;

    for($target){
        /^core$/ && do {
            $xfile = catfile($ENV{PLG},qw( projs bld core.xml ));
            next;
        };

        $xfile = catfile($root,sprintf('%s.bld.%s.xml',$proj, $target));
        last;
    }
    return $xfile;
}

sub _trg_opts_maker {
    my ($bld, $target, @args) = @_;

    $target //= $bld->{target};

    my $om = $bld->_val_('targets', $target, 'opts_maker', @args);

    return $om;

}

1;
 

