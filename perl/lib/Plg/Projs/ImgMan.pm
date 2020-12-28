
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
        $Script OPTIONS
    OPTIONS
            --img_root DIR      directory with images, default is \$ENV{IMG_ROOT}
            --img_db   FILE     SQLite database file, default is IMG_ROOT/img.db
        -c  --cmd      CMD

    EXAMPLES
        $Script --img_root IMG_ROOT --img_db IMG_DB

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

    return $self;
}


1;
 

