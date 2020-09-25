
package Plg::Projs::Prj::Builder::Defs;

use strict;
use warnings;

sub _def_sechyperlinks {
	my ($self) = @_;

	my $def = q{
\def\sechyperlinks{
	\par
	\begin{center}
	    %\colorbox{cyan}{\makebox[5cm][l]{\strut}}
	    \colorbox{cyan}{
	       \makebox[10cm][l]{
	            \large\bfseries
	            \hypersetup{ linkcolor=white }
	
	            \hyperlink{indices}{\indicesname}
	
	            \hypersetup{ linkcolor=yellow }
	            \hyperlink{tabcont}{\contentsname}
	        }
	    }
	\end{center}
}
};

	return $def;

}

1;
 

