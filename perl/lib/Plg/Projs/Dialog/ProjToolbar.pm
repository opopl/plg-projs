
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

    my $expr_pdf = 'projs#action#async_build()';
    my $expr_html = 'projs#action#async_build_htlatex()';
    my $args_pdf = [    
        'gvim',
        '--servername ',$servername,
        '--remote-expr',$expr_pdf
    ];
    my $args_html = [    
        'gvim',
        '--servername ',$servername,
        '--remote-expr',$expr_html
    ];

    my $cmd_pdf = join(" " => @$args_pdf);
    my $cmd_html = join(" " => @$args_html);

    $mw->Button(
        -text    => 'Build PDF',
        -command => sub {
            system("$cmd_pdf");
        } )->pack;
    $mw->Button(
        -text    => 'Build HTML',
        -command => sub {
            system("$cmd_html");
        } )->pack;


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
 

