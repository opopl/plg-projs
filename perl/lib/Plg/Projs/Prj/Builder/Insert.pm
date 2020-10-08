
package Plg::Projs::Prj::Builder::Insert;

use strict;
use warnings;

sub _insert_hyperlinks {
    my ($bld) = @_;

    return [] unless $bld->_val_(qw( sii insert hyperlinks ));

    my @d;
    push @d,
        {
            scts => [qw( section subsection )],
            lines => [ q{ \sechyperlinks } ],
        };

    return [@d];
}

sub _insert_titletoc {
    my ($bld) = @_;

    return [] unless $bld->_val_(qw( sii insert titletoc ));

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
 

