
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

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub init {
    my ($self) = @_;
    
    my $h = {
        img_root => $ENV{IMG_ROOT} || '',
    };
        
    hash_inject($self, $h);
    return $self;
}

sub run {
    my ($self) = @_;

    return $self;
}


1;
 

