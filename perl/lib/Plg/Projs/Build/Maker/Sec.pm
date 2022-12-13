
package Plg::Projs::Build::Maker::Sec;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);

sub _file_sec {
    my ($mkr, $sec, $ref) = @_;

    $ref ||= {};
    my $proj = $ref->{proj} || $mkr->{proj};

    my $s = {
        '_main_' => sub { 
            catfile(
                $mkr->{root},
                join("." => ( $proj, 'tex' )) 
            ) 
        },
        '_bib_' => sub { 
            catfile(
                $mkr->{root},
                join("." => ( $proj, 'refs.bib' )) 
            ) 
        },
    };

    my $ss = $s->{$sec} || sub { 
            catfile(
                $mkr->{root},
                join("." => ( $proj, $sec, 'tex' )) 
            );
    };
    my $f = $ss->();

    return $f;
}

sub _debug_sec {
    my ($mkr, $rootid, $proj, $sec) = @_;

            my $s =<< 'EOF'; 
{\ifDEBUG\vspace{0.5cm}\small\LaTeX~section: \verb|_sec_| project: \verb|_proj_| rootid: \verb|_rootid_|\vspace{0.5cm}\fi}
EOF
    $s =~ s/_sec_/$sec/g;
    $s =~ s/_proj_/$proj/g;
    $s =~ s/_rootid_/$rootid/g;

    return $s;
}


1;
 

