
package Plg::Projs::Tk::ControlPanel::Page::build;

use strict;
use warnings;

sub info {
    {
        name  => 'build',
        label => 'Build'
    }
}

sub blk {
    my ($class,$self) = @_;

    sub { my ($wnd) = @_; $wnd ||= $self->{mw};

	    $wnd->Button(
	        -text => 'bld_compile_xelatex',
	        -command => $self->_vim_server_sub({
	            'expr'  => 'projs#vim_server#pa#bld_compile_xelatex()'
	        })
	    )->pack( ); 
    }
}

1;
 

