
package Plg::Projs::Doc;

use utf8;
use strict;
use warnings;

use FindBin qw($Bin $Script);

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

    my $h = {
        doc_root     => $ENV{DOC_ROOT},
    };

    hash_inject($self, $h);

    return $self;
}

1;


