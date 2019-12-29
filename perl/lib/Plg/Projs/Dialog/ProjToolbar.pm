
package Plg::Projs::Dialog::ProjToolbar;

=head1 NAME

Plg::Projs::Dialog::ProjToolbar - 

=cut

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Tk;
use Tk::widgets;

use FindBin qw( $Bin $Script );

use lib "$Bin/../../base/perl/lib";
use lib "$Bin/../perl/lib";

use base qw( Plg::Base::Dialog );

=head2 tk_proc

Will be called by C<tk_run()> method defined in L<Plg::Base::Dialog>

=cut

sub tk_proc { 
    my ($self, $mw) = @_;

    my $proj       = $self->{data}->{proj} || '';
    my $servername = $self->{data}->{vim}->{servername} || '';

    $mw->title($proj);
    $mw->geometry("400x100+0+0"); 

    my $expr = 'projs#action#async_build()';
    my @args = (    
        'gvim',
        '--servername ',$servername,
        '--remote-expr',$expr
    );
    my $cmd = join(" " => @args);

    $mw->Button(
        -text    => 'async_build',
        -command => sub {
            system("$cmd");
        } )->pack;

    my $lb = $mw->Scrolled("Listbox", 
        -scrollbars => "e", 
        -selectmode => "single")->pack( ); 

    #$lb->insert('end', @projs);

    return $self;
}

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $h = { };
        
    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

    return $self;
}

1;
 

