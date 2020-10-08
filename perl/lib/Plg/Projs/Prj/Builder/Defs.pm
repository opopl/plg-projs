
package Plg::Projs::Prj::Builder::Defs;

use utf8;

use strict;
use warnings;

sub _def_sechyperlinks {
    my ($bld) = @_;

    return [] unless $bld->_val_(qw( sii insert hyperlinks ));

    my $def = q{
\def\indicesname{Указатели}
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
 

