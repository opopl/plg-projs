
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
    my $pwg = eval { Plg::Projs::Piwigo::SQL->new; };

    my $db_file = catfile($root,'projs.sqlite');

    my $h = {
        proj     => $proj,
        root     => $root,
        root_id  => $root_id,
        tags_img => [qw(projs), ($proj, $root_id)],
        pwg      => $pwg,
        db_file  => $db_file,
    };
        
    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

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

sub _files {
    my ($self, $ref) = @_;

    $ref ||= {};

    my $pat  = $ref->{pat} || '';
    my $exts = $ref->{exts} || [];

    my $db_file = $self->{db_file};

    my $proj = $self->{proj};

    my $dbh = dbi_connect({
        dbfile => $db_file
    });

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
 

