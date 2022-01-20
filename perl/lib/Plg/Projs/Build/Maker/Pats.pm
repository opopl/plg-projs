
package Plg::Projs::Build::Maker::Pats;

use strict;
use warnings;

sub _pats {
	my ($self) = @_;

    my $pats = {
         'ii'    => '^\s*\\\\ii\{(.+)\}.*$',
         'iifig' => '^\s*\\\\iifig\{(.+)\}.*$',
         'input' => '^\s*\\\\input\{(\S+)\}.*$',
         'sect'  => '^\s*\\\\(part|chapter|section|subsection|subsubsection|paragraph)\{(.*)\}\s*$',
         'label_sec'  => '^\s*\\\\label\{sec:(.*)\}\s*$',
    };

	return $pats;
}

1;
 

