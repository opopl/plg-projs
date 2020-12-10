
package Plg::Projs::Tk::ControlPanel;

=head1 NAME

Plg::Projs::Tk::Dialog::ControlPanel - 

=cut

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Tk;
use Tk::NoteBook;
use Tk::widgets;
use Tk::MatchEntry;

use FindBin qw( $Bin $Script );

use lib "$Bin/../../base/perl/lib";
use lib "$Bin/../perl/lib";

use Plg::Projs::Prj;

use Base::Util qw(
	iswin
);

use Base::Arg qw(
    hash_update
);

use base qw( 
    Base::Obj
    Plg::Base::Tk::Dialog 
    Plg::Projs::Tk::ControlPanel::Wnd
);

use Base::Arg qw(
    hash_update
);

#https://www.perlmonks.org/?node_id=1185809
sub Tk::Separator
{
    my ($self, %rest ) = @_;
    my $direction = delete $rest{'-orient'} // 'horizontal';
    $self->Frame( %{ {%rest, -bg => 'black',
        $direction eq 'vertical' ? '-width' : '-height' => 2 } } );
}

=head2 tk_proc

Will be called by C<tk_run()> method defined in L<Plg::Base::Tk::Dialog>

=cut

sub tk_proc { 
    my ($self, $mw) = @_;

    $self->{mw} = $mw;

    foreach my $x (qw(root rootid proj)) {
        $self->{$x}   = $self->{data}->{$x} || '';
    }
        
    my $proj = $self->{proj};

    $self->{prj} = Plg::Projs::Prj->new( 
        proj    => $proj,
        root    => $self->{root},
        root_id => $self->{rootid},
    );

    my $servername = $self->_val_('data vim servername') || '';

    $mw->title($proj);

    my $geom = $self->{geom};
    my $g = sprintf(q{%sx%s},@{$geom}{qw(width height)});

    $mw->geometry($g); 

    $self
        ->tk_add_pages
        ;

    return $self;
}

sub nb_create {
    my ($self) = @_;

    my $mw = $self->{mw};
    my $nb = $mw
        ->NoteBook( )
        ->pack( 
            #-expand => 1,
            #-fill   => 'x'
        ); 
    $self->{nb} = $nb;

    return $self;
}

sub nb_add {
    my ($self, $ref) = @_;
    
    my $mw = $self->{mw};
    my $nb = $self->{nb};

    $ref ||= {};
    my $pages = $ref->{pages} || [];
    if (@$pages) {
        foreach my $page (@$pages) {
            $self->nb_add($page)
        }
        return $self;
    }

    my $name  = $ref->{name} || '';
    my $label = $ref->{label} || '';
    my $blk   = $ref->{blk} || sub { };

    my $p = $nb->add($name, -label => $label); 

    $blk->($p);

    $self->{nb_pages} ||= {};

    $self->{nb_pages}->{$name} = { p => $p, %$ref };

    return $self;
}

sub _nb_page {
    my ($self, $name) = @_;

    my $sp = $self->{nb_pages}->{$name} || {};
    my $p = $sp->{p};

    return $p;
}

sub tk_add_pages {
    my ($self) = @_;

    my $prj = $self->{prj};

	my @page_order;
	push @page_order, 'build';
	my $pf = 'Plg::Projs::Tk::ControlPanel::Page';

	my @pages;
	for(@page_order){
		my $pack = sprintf('%s::%s',$pf, $_);
		eval { require $pack; };
		if($@){
			next;
		}

		#push @pages, {
			#name => $n
		#}
	}
	

    $self
        ->nb_create
        ->nb_add({ pages => \@pages })
        ;
    
    return $self;
}

sub tk_sep_hz {
    my ($self, $wnd) = @_;

    $wnd ||=  $self->{mw};

    $wnd->Tk::Separator( 
        -orient => 'horizontal')
    ->pack( 
        -side => 'top', 
        -fill => 'x' 
    );

    return $self;
}

sub tk_frame_secs { 
    my ($self) = @_;

    my $mw = $self->{mw};

    my $fr_secs = $mw->Frame();

    $mw->Label( 
        -text => 'Sections', 
        -height => 2,
    )->pack;
        
    $fr_secs->pack(-side => 'top', -fill => 'x');

    $mw->Frame( 
        -height => 2, 
        -bg => 'black',
    )->pack( 
        -side => 'top', 
        -fill => 'x' );

    my $secs = [qw(
        _main_
        body 
        preamble 
        tabcont
        cfg
    )];

    foreach my $sec (@$secs) {
        my $expr = sprintf("projs#vim_server#sec_open('%s')",$sec);
        $fr_secs->Button(
            -text    => $sec,
            -command => $self->_vim_server_sub({
                'expr'  => $expr
            })
        )->pack(-side => 'left');
    }

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
        '--remote-expr',( iswin() ? $expr : qq{"$expr"} )
    ];

    my $cmd = join(" " => @$args);
    return $cmd;
}

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $h = { 
        geom => {
            width  => 800,
            height => 500,
        }
    };
    hash_update($self, $h, { keep_already_defined => 1 });

    return $self;
}

1;
 

