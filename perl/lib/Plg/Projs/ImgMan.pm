
package Plg::Projs::ImgMan;

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use Base::Arg qw( hash_inject );
use Base::DB qw(
    dbh_do
    dbh_insert_hash
    dbh_select
    dbh_select_as_list
    dbi_connect
);
use Getopt::Long qw(GetOptions);
use File::Basename qw(basename dirname);
use FindBin qw($Bin $Script);
use File::Spec::Functions qw(catfile);
use Data::Table;

use Image::Info qw(
    image_info
    image_type
);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub _img_root {
    my ($self) = @_;
}

sub init {
    my ($self) = @_;
    
    my $h = {
        img_root => $ENV{IMG_ROOT} || '',
    };
        
    hash_inject($self, $h);
    return $self;
}

sub init_db {
    my ($self) = @_;

    $self->{img_db} ||= catfile($self->{img_root},'img.db');
	
	my $ref = {
		dbfile => $self->{img_db},
	};
	
	my $dbh = $self->{img_dbh} = dbi_connect($ref);

    return $self;
}

sub c_list {
    my ($self) = @_;

	my $data=[];
	my $rows = $self->_imgs;
	my $header = [qw(inum ext type img sec)];
	foreach my $row (@$rows) {
		push @$data, [ map { $row->{$_} } @$header ];
	}
	my $dt = Data::Table->new($data,$header,0);
	print $dt->tsv . "\n";

    return $self;
}

sub _imgs {
    my ($self, $ref) = @_;
	$ref ||= {};
	my $cond = $ref->{cond} || '';

	my $dbh = $self->{img_dbh};
    return $self unless $dbh;

	my $ref = {
		dbh  => $dbh,
		q    => q{ SELECT * FROM imgs },
		p    => [  ],
		cond => $cond,
	};
	
	my ($rows) = dbh_select($ref);
	return $rows;
}

sub c_info {
    my ($self) = @_;

	my $q = q{ SELECT sql FROM sqlite_master WHERE name = ? };
	my $p = [qw( imgs )];

	my $dbh = $self->{img_dbh};
    return $self unless $dbh;

	my $ref = {
		dbh => $dbh,
		q   => $q,
		p   => $p,
	};
	
	my ($rows) = dbh_select($ref);
	my $sql = $rows->[0]->{'sql'} || '' ;
	print $sql . "\n";

    return $self;
}

sub c_cnv {
    my ($self) = @_;

	my $imgs = $self->_imgs;

    return $self;
}

      
sub get_opt {
    my ($self) = @_;
    
    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));
    
    my (@optstr, %opt);
    @optstr = ( 
        "img_root=s",
        "img_db=s",
        "cmd|c=s",
    );
    
    unless( @ARGV ){ 
        $self->dhelp;
        exit 0;
    }else{
        GetOptions(\%opt,@optstr);
        $self->{opt} = \%opt;
    }

    foreach my $k (keys %opt) {
        $self->{$k} = $opt{$k};
    }

    return $self;    
}

sub dhelp {
    my ($self) = @_;

    my $s = qq{

    USAGE
        perl $Script OPTIONS
    OPTIONS
            --img_root DIR      directory with images, default is \$ENV{IMG_ROOT}
            --img_db   FILE     SQLite database file, default is IMG_ROOT/img.db
        -c  --cmd      CMD

    EXAMPLES
        perl $Script --img_root IMG_ROOT --img_db IMG_DB

    };

    print $s . "\n";

    return $self;    
}

sub run {
    my ($self) = @_;

    $self
        ->get_opt
        ->init_db
        ;
	my $cmd = $self->{cmd};
	if ($cmd) {
		my $sub = 'c_' . $cmd;
		if ($self->can($sub)){
			$self->$sub;
		}else{
			warn qq{[ImgMan] command not defined: $cmd} . "\n";
		}
	}

    return $self;
}


1;
 

