
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

	$self->{mw} = $mw;

    my $proj       = $self->{data}->{proj} || '';
    my $servername = $self->{data}->{vim}->{servername} || '';

    $mw->title($proj);
    $mw->geometry("400x100+0+0"); 

	$self
		->tk_frame_build
		->tk_frame_view
		->tk_frame_secs
		;

    return $self;
}

sub tk_frame_secs { 
    my ($self) = @_;

	my $mw = $self->{mw};

	my $fr_secs = $mw->Frame()->pack(-side => 'top', -fill => 'x');

    $fr_secs->Button(
        -text    => 'tabcont',
        -command => $self->_vim_server_sub({
			'expr'  => "projs#vim_server#sec_open('tabcont')"
		})
    )->pack(-side => 'left');

    return $self;
}

sub tk_frame_view { 
    my ($self) = @_;

	my $mw = $self->{mw};

	my $fr_view = $mw->Frame()->pack(-side => 'top', -fill => 'x');

    $fr_view->Button(
        -text    => 'View HTML',
        -command => $self->_vim_server_sub({
			'expr'  => 'projs#vim_server#html_out_view()'
		})
    )->pack(-side => 'left');

    $fr_view->Button(
        -text    => 'View PDF',
        -command => $self->_vim_server_sub({
			'expr'  => 'projs#vim_server#pdf_out_view()'
		})
    )->pack(-side => 'left');

    return $self;
}

sub tk_frame_build { 
    my ($self) = @_;

	my $mw = $self->{mw};

	my $fr_build = $mw->Frame()->pack(-side => 'top', -fill => 'x');

    $fr_build->Button(
        -text    => 'Build PDF',
        -command => $self->_vim_server_sub({
			'expr'  => 'projs#vim_server#async_build()'
		})
    )->pack(-side => 'left');

    $fr_build->Button(
        -text    => 'Build HTML',
        -command => $self->_vim_server_sub({
			'expr'  => 'projs#vim_server#async_build_htlatex()'
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
 

