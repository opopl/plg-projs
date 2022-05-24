
package Plg::Projs::Prj::Section;

use strict;
use warnings;

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

use Base::Arg qw( 
    hash_inject
);

sub init {
    my ($self) = @_;
    
    #$self->SUPER::init();
    
    my $h = {
        # Plg::Projs::Prj instance
        prj => undef,
    };
        
    hash_inject($self, $h);
    return $self;
}

1;
 

