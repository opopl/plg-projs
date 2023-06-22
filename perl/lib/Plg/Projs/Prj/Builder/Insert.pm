
package Plg::Projs::Prj::Builder::Insert;

use strict;
use warnings;

use Base::Arg qw(
  varval
);

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

sub _insert_story {
    my ($bld) = @_;

    return [] unless $bld->_val_(qw( sii insert story ));

    my $mkr = $bld->{maker} || {};
    my $r_sec = $mkr->{r_sec} || {};

    my $sec   = $r_sec->{sec};
    my $title = $r_sec->{title};
    my $date  = $r_sec->{date};

    return [] unless $sec && $title && $date;

    ( my $date_dot = $date ) =~ s/_/./g;
    my $cut = varval('vars.layout.header.title_cut', $bld) || 20;
    $DB::single = 1;
    $cut = int($cut);

    $title =~ s/\\enquote\{([^{}]*)\}/$1/g;
    my $title_cut = (length($title) < $cut) ? $title : ( substr($title, 0, $cut) . '...' );

    my @lines;
    push @lines,
        '',
        sprintf('\def\storySec{%s}',$sec),
        sprintf('\def\storyTitle{%s}',$title_cut),
        sprintf('\def\storyDate{%s}',$date_dot),
        '\def\storyLink{\hyperlink{\storySec}{\storyTitle}}',
        '\hypertarget{\storySec}{}',
        '',
        '\pagestyle{ltsStory}',
        '',
        ;

    my @d;
    push @d,
        {
            scts => [qw( subsection )],
            lines => [@lines],
            at_end => [
              '\pagestyle{fancy}'
            ],
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
 

