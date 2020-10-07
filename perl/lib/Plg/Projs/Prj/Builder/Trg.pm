
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
    my ($self) = @_;

    foreach my $trg ($self->_trg_list) {
        my $sub = 'trg_inj_' . $trg;
        if ($self->can($sub)) {
            $self->$sub;
        }
    }
    return $self;
}

sub _trg_list {
    my ($self) = @_;

    @{ $self->{trg_list} || [] };
}

sub trg_inject {
    my ($self, $trg, $hash ) = @_;

    hash_inject($self, { targets => { $trg => $hash }} );

    return $self;

}

sub trg_apply {
    my ($self, $target) = @_;

    $target //= $self->{target};

    my $ht = $self->_val_('targets', $target);
    hash_apply($self, $ht);

    return $self;

}

sub _trg_data {
    my ($self, $target) = @_;

    $target //= $self->{target};
}

sub _trg_dom {
    my ($self, $target) = @_;

    $target //= $self->{target};
    my $dom = $self->_val_('dom_trg ' . $target);

    unless ($dom) {
        my $xfile = $self->_trg_xfile($target);
        return unless (-e $xfile);

        my $cache = XML::LibXML::Cache->new;
        $dom = $cache->parse_file($xfile);

        $self->{dom_trg}->{$target} = $dom;
    }

    return $dom;

}

sub _trg_dom_find {
    my ($self, $target) = @_;

    $target //= $self->{target};
    my $dom = $self->_trg_dom($target);

    my $data;
    return $data;

}

sub trg_load_xml {
    my ($self, $target) = @_;

    $target //= $self->{target};

    my $dom = $self->_trg_dom($target);
    return $self unless $dom;

    my $pl = xml2dict($dom, attr => '', array => [qw( scts )] );
    #my $secs = deepvalue($pl,qw(bld sii secs));
    #print Dumper($secs) . "\n";
    #exit 1;

    my $h = $pl->{bld};

    my $ht = $self->_val_('targets',$target) || {};

    hash_apply($ht, $h);

    $self->{'targets'}->{$target} = $ht;

    #print Dumper($self->_val_('targets',$target)) . "\n";
    #exit 1;

    return $self;
}

sub _trg_xfile {
    my ($self, $target) = @_;

    $target //= $self->{target};

    my $proj = $self->{proj};
    my $root = $self->{root};

    my $xfile = catfile($root,sprintf('%s.bld.%s.xml',$proj, $target));
    return $xfile;
}

sub _trg_opts_maker {
    my ($self, $target, @args) = @_;

    $target //= $self->{target};

    my $om = $self->_val_('targets', $target, 'opts_maker', @args);

    return $om;

}

1;
 

