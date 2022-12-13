
package Plg::Projs::Sec::Saved;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

use base qw(
    Plg::Projs::Prj
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

    return $self;
}

1;
 

