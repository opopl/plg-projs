
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

    my $expr = 'projs#vim_server#async_build_htlatex()';

    $mw->Button(
        -text    => 'Build PDF',
        -command => $self->_vim_server_sub({
			'expr'  => 'projs#vim_server#async_build()'
		})
    )->pack(-side => 'left');

    $mw->Button(
        -text    => 'Build HTML',
        -command => $self->_vim_server_sub({
			'expr'  => 'projs#vim_server#async_build_htlatex()'
		})
    )->pack(-side => 'left');

    $mw->Button(
        -text    => 'View HTML',
        -command => $self->_vim_server_sub({
			'expr'  => 'projs#vim_server#html_out_view()'
		})
    )->pack(-side => 'left');

    $mw->Button(
        -text    => 'View PDF',
        -command => $self->_vim_server_sub({
			'expr'  => 'projs#vim_server#pdf_out_view()'
		})
    )->pack(-side => 'left');

   $mw->Button(
        -text    => 'tabcont',
        -command => $self->_vim_server_sub({
			'expr'  => "projs#vim_server#sec_open('tabcont')"
		})
    )->pack(-side => 'left');

    return $self;
}

sub _vim_servername {
    my ($self) = @_;

    my $servername = $self->{data}->{vim}->{servername} || '';
	return $servername;
}

sub _vim_server_sub {
    my ($self, $ref) = @_;

	$ref ||= {};
	my $expr = $ref->{expr} || '';

	return sub { 
		my $cmd = $self->_vim_server_cmd({ 'expr'  => $expr });
		system("$cmd");
	};
}

sub _vim_server_cmd {
    my ($self,$ref) = @_;

	$ref ||= {};
	my $expr = $ref->{expr} || '';

    my $args = [    
        'gvim',
        '--servername ',$self->_vim_servername,
        '--remote-expr',$expr
    ];

    my $cmd = join(" " => @$args);
	return $cmd;
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
 

