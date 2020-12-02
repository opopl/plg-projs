
package Plg::Projs::Scripts::Zlan;

use strict;
use warnings;

use utf8;
binmode STDOUT,':encoding(utf8)';

use Base::Arg qw( hash_inject );
use Cwd qw(getcwd);

use Plg::Projs::Prj;

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub init {
    my ($self) = @_;
    
    my $prj = Plg::Projs::Prj->new();
    my $h = {
        prj    => $prj,
        rootid => getcwd(),
    };
        
    hash_inject($self, $h);
    return $self;
}

1;
 

