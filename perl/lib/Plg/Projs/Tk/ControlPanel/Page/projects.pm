
package Plg::Projs::Tk::ControlPanel::Page::projects;

use strict;
use warnings;

sub info {
	{
		name  => 'projects',
		label => 'Projects',
	}
}

sub blk {
	my ($self,$wnd) = @_;

	$self
		->wnd_fill_projects_entry($wnd)
		#->wnd_fill_projects_buttons($wnd)
	;
}

1;
 

