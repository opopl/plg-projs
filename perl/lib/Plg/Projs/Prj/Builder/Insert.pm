
package Plg::Projs::Prj::Builder::Insert;

use strict;
use warnings;

sub _insert_hyperlinks {
	my ($self) = @_;

    my @d;
    push @d,
        {
			scts => [qw( section subsection )],
			lines => [
q{
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
                        ]
        };

	return [@d];
}

sub _insert_titletoc {
    my $self = shift;

    my @d;
    push @d,
            {
###ttt_section
             scts    => [qw( section )],
             lines => [
                 ' ',
                 '\startcontents[subsections]',
    '\printcontents[subsections]{l}{2}{\addtocontents{ptc}{\setcounter{tocdepth}{3}}}',

             ],
             lines_stop => [
                 '\stopcontents[subsections]',
            ]
        },
        {
             scts    => [qw( chapter )],
             lines => [
                 ' ',
                 '\startcontents[sections]',
    '\printcontents[sections]{l}{1}{\addtocontents{ptc}{\setcounter{tocdepth}{1}}}',
                 ' ',
             ],
             lines_stop => [
                 '\stopcontents[sections]',
            ]
        },
        ;
    return [@d];
}

1;
 

