
package Plg::Projs::Prj;

use strict;
use warnings;

use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use File::Spec::Functions qw(catfile);
use Data::Dumper qw(Dumper);

use Plg::Projs::Piwigo::SQL;

use Base::DB qw(
    dbi_connect
    dbh_select_as_list
    dbh_select
);

use Base::Arg qw(hash_update);


sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub init {
    my $self = shift;

    my ($proj)  = ($Script =~ m/^(\w+)\..*$/);
    my $root_id = basename($Bin);
    my $root    = $Bin;

    local @ARGV = ();

    my $h = {
        proj     => $proj,
        root     => $root,
        root_id  => $root_id,
		load_pwg => 0,
    };

    my @k = keys %$h;

    hash_update($self, $h, { keep_already_defined => 1 });

	if ($self->{load_pwg}) {
		$self->{pwg} ||= eval { Plg::Projs::Piwigo::SQL->new; };
	}

    $self->{db_file} ||= catfile($self->{root},'projs.sqlite');
	$self->{tags_img} ||= [qw(projs), ( $self->{proj}, $self->{root_id} )];

	$self->init_db;

    return $self;
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

sub init_db {
	my ($self) = @_;

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
 

