
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

use YAML::XS qw( LoadFile Load Dump DumpFile );

use Base::XML::Dict qw(xml2dict);
use XML::LibXML::Cache;

use Base::DB qw(
    dbi_connect
    dbh_select_as_list
    dbh_select
    dbh_select_first

    jcond
    cond_where
);


use base qw(
    Base::Opt
    Plg::Projs::Prj::Author
    Plg::Projs::Prj::Data
);

use Base::Arg qw(
    hash_inject
    dict_update
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
        ->init_db
        ;

    return $self;
}

sub prj_load_yml {
    my ($self) = @_;

    return $self if $self->{prj_skip_load_yml};
    
    my $proj = $self->{proj};
    my $root = $self->{root};

    my $yfile = $self->_prj_yfile;
    return $self unless -f $yfile;

    my $d = LoadFile($yfile) // {};
    $self->{cnf} //= {};
    dict_update($self->{cnf}, $d);

    $self->cnf_trg_list;

    return $self;
}

sub cnf_trg_list {
    my ($self) = @_;

    my $proj = $self->{proj};
    my $root = $self->{root};

    my $include = $self->_val_list_ref_('cnf targets include');
    my $exclude = $self->_val_list_ref_('cnf targets exclude');

    my @t;
    my $pat = qr/^$proj\.bld\.(.*)\.yml$/;
    find({ 
        wanted => sub { 
            return unless /$pat/;
            push @t,$1;
        } 
    },$root
    );
    my $inc_all = 0;
    $inc_all = ( grep { /^_all_$/ } @$include ) ? 1 : 0;
    $inc_all = 0 if @$exclude;

    my %include = map { $_ => 1 } @$include;
    my %exclude = map { $_ => 1 } @$exclude;
    unless ($inc_all) {
        @t = grep { $include{$_} && !$exclude{$_} } @t;
    }
    $self->{trg_list} = [@t];

    return $self;
}

sub _prj_yfile {
    my ($self) = @_;

    my $proj = $self->{proj};
    my $root = $self->{root};

    my $yfile = catfile($root,sprintf('%s.yml',$proj));
    return $yfile;
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

sub _secs_select {
    my ($self, $select) = @_;
    $select ||= {};

    my $list = [];

    my (%wh, %conds, %tbls);
    my (@cond, @params);

    my $ops = $select->{'@op'} || 'and';
    my $limit = $select->{limit} || '';
    my $where = $select->{where} || {};
  
    my @keys = qw( tags author_id );
    my %key2col = (
       'tags' => 'tag'
    );
    my @ij;
    foreach my $key (@keys) {
        # alias index for joined tables, e.g. t0, t1, ...
        my $ia = 0;
  
        my @cond_k;
  
        my $wk = $wh{$key} = $select->{$key};
        next unless $wk;
  
        my $colk = $key2col{$key} || $key;
        my $tk = '_info_projs_' . $key;
        
        if (ref $wk eq 'HASH') {
          foreach my $op (qw( or and )) {
            my $vals = $wk->{$op};
            next unless $vals;
            next unless ref $vals eq 'ARRAY';
  
            my @cond_op;
  
            foreach my $v (@$vals) {
              $ia++;
              my $tka = $key . $ia;
              push @ij, { 
                 'tbl'       => $tk,
                 'tbl_alias' => $tka,
                 'on'        => 'file',
              };
              push @cond_op, sprintf('%s.%s = ?', $tka, $colk);
              push @params, $v;
            }
            push @cond_k, jcond($op => \@cond_op);
          }
        }

        my $opk = $wk->{'@op'} || 'and';
        push @cond, jcond($opk => \@cond_k, braces => 1);
    }

    my ($q_where, $p_where) = cond_where($where);
    $DB::single = 1;
    if ($q_where) {
        push @cond, $q_where;
        push @params, @$p_where;
    }
  
    my $cond;
    if (@cond) {
      $cond = 'WHERE ';
      $cond .= jcond($ops => \@cond, braces => 1);
    }
  
    my $ref = {
        dbh     => $self->{dbh},
        t       => 'projs',
        t_alias => 'p',
        f       => [qw( p.sec )],
        ij      => \@ij,
        p       => \@params,
        cond    => $cond,
        limit   => $limit,
    };
    push @$list, dbh_select_as_list($ref);

    $DB::single = 1 if $select->{dbg};

    wantarray ? @$list : $list ;
}

sub _sec_data {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($proj, $sec) = @{$ref}{qw(proj sec)};
    $proj ||= $self->{proj};

    my ($rows,$cols,$q,$p) = dbh_select({
        dbh     => $self->{dbh},
        q       => q{ SELECT * FROM projs },
        w       => { proj => $proj, sec => $sec }
    });
    my $rw = $rows->[0];
    return $rw;
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
 

