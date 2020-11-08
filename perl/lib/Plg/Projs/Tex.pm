
package Plg::Projs::Tex;

use strict;
use warnings;
use utf8;

binmode STDOUT,':encoding(utf8)';

=head3 _tex_include_graphics

    my $tex = $self->_tex_include_graphics({
        width    => $width,
        rel_path => $rel_path,
    });

=cut

sub _tex_include_graphics {
    my ($self, $ref) = @_;

    my $w        = $ref->{width};
    my $rel_path = $ref->{rel_path};

    my $pic_opts = $self->_tex_pic_opts({ width => $w });

    my @tex;

    push @tex,
        sprintf(q{\def\picpath{\pwgroot/%s}},$rel_path),
        sprintf(q{\includegraphics[%s]{\picpath}}, $pic_opts ),
        ;

    return @tex;
}

sub _tex_pic_opts {
    my ($self, $ref) = @_;

    my $width = $ref->{width};

    sprintf(q{width=%s\textwidth},$width); 
};

1;
 

