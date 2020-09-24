
package Plg::Projs::Build::Maker::Sec;

use strict;
use warnings;

use File::Spec::Functions qw(catfile);

sub _file_sec {
    my ($self, $sec, $ref) = @_;

    $ref ||= {};
    my $proj = $ref->{proj} || $self->{proj};

    my $s = {
        '_main_' => sub { 
            catfile(
                $self->{root},
                join("." => ( $proj, 'tex' )) 
            ) 
        },
        '_bib_' => sub { 
            catfile(
                $self->{root},
                join("." => ( $proj, 'refs.bib' )) 
            ) 
        },
    };

    my $ss = $s->{$sec} || sub { 
            catfile(
                $self->{root},
                join("." => ( $proj, $sec, 'tex' )) 
            );
    };
    my $f = $ss->();

    return $f;
}

sub _debug_sec {
    my ($self, $root_id, $proj, $sec) = @_;

            my $s =<< 'EOF'; 
\vspace{0.5cm}
{\ifDEBUG\small\LaTeX~section: \verb|_sec_| project: \verb|_proj_| rootid: \verb|_rootid_|\fi}
\vspace{0.5cm}
EOF
    $s =~ s/_sec_/$sec/g;
    $s =~ s/_proj_/$proj/g;
    $s =~ s/_rootid_/$root_id/g;

    return $s;
}


1;
 

