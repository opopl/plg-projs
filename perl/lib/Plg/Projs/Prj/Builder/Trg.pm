
package Plg::Projs::Prj::Builder::Trg;

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Base::XML::Dict qw(xml2dict);
use YAML qw( LoadFile Load Dump DumpFile );

use Deep::Hash::Utils qw(deepvalue);

use Base::Arg qw(
    hash_inject
    dict_update
    dict_rm_ctl
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
    Plg::Projs::Prj::Builder::Trg::core
);

sub inj_targets {
    my ($bld) = @_;

    $bld->trg_inj_core;

    foreach my $trg ($bld->_trg_list) {
        my $sub = 'trg_inj_' . $trg;
        if ($bld->can($sub)) {
            $bld->$sub;
        }
    }
    return $bld;
}

sub trg_list_add {
    my ($bld, @t) = @_;
    $bld->{trg_list} ||= [];

    push @{$bld->{trg_list}}, @t;
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

sub trg_adjust {
    my ($bld, $target) = @_;

    $target //= $bld->{target};

    return $bld;
}

sub trg_apply {
    my ($bld, $target) = @_;

    $target //= $bld->{target};

    my $opts = {};
    my $ht = $bld->_val_('targets', $target);
    $opts->{ctl} = 1;
    dict_update($bld, $ht, $opts);

    return $bld;
}

sub trg_load_yml {
    my ($bld, $ref) = @_;

    $ref ||= {};
    my $target = $bld->_opt_($ref,'target');

    my $yfile = $ref->{yfile} || $bld->_trg_yfile($target);
    return $bld unless -f $yfile;

    my $h_bld = LoadFile($yfile);
    return $bld unless $h_bld;

    my $ht = $bld->_val_('targets',$target) || {};
    dict_update($ht, $h_bld);

    $bld->{'targets'}->{$target} = $ht;

    return $bld;
}

sub _trg_yfile {
    my ($bld, $target) = @_;

    $target //= $bld->{target};

    my ($proj, $root) = @{$bld}{qw(proj root)};
    my $yfile;

    for($target){
        /^core$/ && do {
            $yfile = catfile($ENV{PLG},qw( projs bld core.yml ));
            next;
        };

        $yfile = catfile($root,sprintf('%s.bld.%s.yml',$proj, $target));
        last;
    }
    return $yfile;
}

sub _trg_opts_maker {
    my ($bld, $target, @args) = @_;

    $target //= $bld->{target};

    my $om = $bld->_val_('targets', $target, 'opts_maker', @args);

    return $om;

}

1;
 

