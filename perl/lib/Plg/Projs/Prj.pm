
package Plg::Projs::Prj;

use utf8;
use strict;
use warnings;

use Deep::Hash::Utils qw( deepvalue );

use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use File::Spec::Functions qw(catfile);
use Data::Dumper qw(Dumper);

use File::Find qw(find);

use Base::XML::Dict qw(xml2dict);
use XML::LibXML::Cache;

use Plg::Projs::Piwigo::SQL;

use Base::DB qw(
    dbi_connect
    dbh_select_as_list
    dbh_select
);

use Base::Arg qw(
    hash_inject
);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub init {
    my ($self) = @_;

    $self
        ->init_proj
        #->init_pwg
        ->init_db
        ;

    return $self;
}

sub prj_load_xml {
    my ($self) = @_;

	return $self if $self->{prj_skip_load_xml};
    
    my $proj = $self->{proj};
    my $root = $self->{root};

    my $xfile = $self->_prj_xfile;
    unless (-e $xfile) {
        return $self;
    }

    my $cache = XML::LibXML::Cache->new;
    my $dom = $cache->parse_file($xfile);

    $self->{dom_xml_trg} = $dom;

    my $pl = xml2dict($dom, attr => '');
    $self->{cnf} = $pl->{$proj} || {};


    my $include = $self->_val_list_ref_('cnf targets include');
    my $exclude = $self->_val_list_ref_('cnf targets exclude');

    my @t;
    my $pat = qr/^$proj\.bld\.(.*)\.tml$/;
    find({ 
        wanted => sub { 
            return unless /$pat/;
            push @t,$1;
        } 
    },$root
    );
    my $inc_all = 0;
    $inc_all = grep { /^_all_$/ } @$include ? 1 : 0;
    $inc_all = 0 if @$exclude;

    my %include = map { $_ => 1 } @$include;
    my %exclude = map { $_ => 1 } @$exclude;
    unless ($inc_all) {
        @t = grep { $include{$_} && !$exclude{$_} } @t;
    }
    $self->{trg_list} = [@t];

    return $self;
}

sub _prj_xfile {
    my ($self) = @_;

    my $proj = $self->{proj};
    my $root = $self->{root};

    my $xfile = catfile($root,sprintf('%s.xml',$proj));
    return $xfile;
}

sub fill_files {
    my ($self) = @_;

    $self->{files} = {};
    foreach my $ext (qw( tex pl dat )) {
        my $r = { 
            'exts' => [ $ext ],
        };
        $self->{files}->{$ext} = $self->_files($r);
    }

    return $self;
}

sub _projects {
    my ($self, $ref) = @_;

    $ref ||= {};
    my $pat = $ref->{pat} || '';

    my $projects = [];

    my $r = {
        dbh     => $self->{dbh},
        q       => q{ SELECT DISTINCT proj FROM projs },
        p       => [],
    };

    my ($list,$cols) = dbh_select($r);
    foreach my $row (@$list) {
        my $proj = $row->{proj};
        push @$projects, $proj;
    }

    wantarray ? @$projects : $projects;
}

sub init_pwg {
    my ($self) = @_;

    if ($self->{load_pwg}) {
        local @ARGV = ();
        $self->{pwg} ||= eval { Plg::Projs::Piwigo::SQL->new; };
    }

    $self->{tags_img} ||= [qw(projs), ( $self->{proj}, $self->{root_id} )];

    return $self;
}

sub init_proj {
    my ($self) = @_;

    return $self if $self->{proj};

    my ($proj)  = ($Script =~ m/^(\w+)\..*$/);
    my $root_id = basename($Bin);
    my $root    = $Bin;

    my $h = {
        proj     => $proj,
        root     => $root,
        root_id  => $root_id,
        load_pwg => 0,
    };

    hash_inject($self, $h);

    return $self;
}

sub init_db {
    my ($self) = @_;

    return $self if $self->{prj_skip_db};

    $self->{db_file} ||= catfile($self->{root},'projs.sqlite');
    my $db_file = $self->{db_file};

    my $dbh = dbi_connect({
        dbfile => $db_file
    });
    $self->{dbh} = $dbh;

    return $self;
}

sub _files {
    my ($self, $ref) = @_;

    $ref ||= {};

    my $pat  = $ref->{pat} || '';
    my $exts = $ref->{exts} || [];

    my $proj = $self->{proj};

    my $dbh = $self->{dbh};

    my $cond = q{ WHERE proj = ? };
    if (@$exts) {
        $cond .= sprintf(' AND (%s)', join(" OR ",map { sprintf('file LIKE "%%.%s"',$_) } @$exts ));
    }

    my $r = {
        dbh     => $dbh,
        q       => q{ SELECT file, sec FROM projs },
        p       => [ $proj ],
        cond    => $cond,
    };

    my ($list,$cols) = dbh_select($r);

    wantarray ? @$list : $list;

}

1;
 

