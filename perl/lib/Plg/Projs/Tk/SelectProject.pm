
package Plg::Projs::Dialog::SelectProject;

=head1 NAME

Plg::Projs::Dialog::SelectProject - Tk dialog for selecting a project

=cut

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Tk;
use Tk::widgets;

use FindBin qw( $Bin $Script );

use lib "$Bin/../../base/perl/lib";
use lib "$Bin/../perl/lib";

use base qw( 
    Base::Obj
    Plg::Base::Dialog 
);

use Base::Arg qw( hash_inject );

=head2 tk_proc

Will be called by C<tk_run()> method defined in L<Plg::Base::Dialog>

=cut

sub tk_proc { 
    my ($self, $mw) = @_;

    my $projs = $self->_val_(qw(data projs)) || [];

    my $lb = $mw->Scrolled("Listbox", 
        -scrollbars => "e", 
        -selectmode => "single")->pack( ); 

    $lb->insert('end', @$projs);

    return $self;
}

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $h = { };
    hash_inject($self, $h);

    return $self;
}

1;
 

