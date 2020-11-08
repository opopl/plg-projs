
package Plg::Projs::Prj::Img;

use strict;
use warnings;

use Base::Arg qw(
	hash_inject
);

use base qw(
    Plg::Projs::Prj
);
use Data::Dumper qw(Dumper);

sub init {
    my ($self) = @_;

    $self->Plg::Projs::Prj::init();

    my @tags_base;
    push @tags_base,
        @{$self->{tags_img}}, @{$self->{tags_img_new} || [] }
        ;

    my $h = {
        tags_base => [ @tags_base ]
    };

	hash_inject($self, $h);

    return $self;
}

sub _range_tabular {
    my ($self, $range, $cols) = @_;

    my @lines;
    if (@$range >= $cols) {
        push @lines, $self->_range_tabular_rows($range, $cols);
    }

    push @lines, $self->_range_tabular_line($range, $cols);

    return @lines;
}

sub _range_tabular_rows {
    my ($self, $range, $cols) = @_;

    my @tex_lines;
    push @tex_lines,sprintf(q{\begin{tabular}{%s}},'c' x $cols);

    my $pwg       = $self->{pwg};
    my @tags_base = @{$self->{tags_base}};
    
    my $num;

    my $j=1;

    my $tg;
    while(@$range) {
        $tg = shift @$range;

        my $eol = ( $j % $cols == 0 ) ? q{\\\\} : q{&};
    
        push @tex_lines,
            $pwg->_img_include_graphics({ 
                 width => $self->{width_cell}, 
                 tags  => [ @tags_base, $tg ] }),
            $eol,
            '%' . 'x' x 50,
            ;

        if (@$range < ($cols-1)) {
            last;
        }
        $j++;
    }

    push @tex_lines,
        q{\end{tabular}};

    return @tex_lines;
}

sub _range_tabular_line {
    my ($self, $range) = @_;

    my @tex_lines;

    my $n_cols = scalar @$range;
    return () unless $n_cols;

    push @tex_lines,sprintf(q{\begin{tabular}{%s}},'c' x $n_cols);

    my $pwg       = $self->{pwg};
    my @tags_base = @{$self->{tags_base}};
    
    my $j=1;

    my $tg;
    while(@$range) {
        $tg = shift @$range;

        my $eol = ( $j % $n_cols == 0 ) ? q{\\\\} : q{&};
    
        push @tex_lines,
            $pwg->_img_include_graphics({ 
                 width => $self->{width_last}, 
                 tags  => [ @tags_base, $tg] }),
            $eol,
            '%' . 'x' x 50,
            ;

        $j++;
    }

    push @tex_lines,
        q{\end{tabular}};

    return @tex_lines;
}


sub run {
    my ($self) = @_;

	my $tex = $self->tex;
    print $tex . "\n";


}

sub tex {
    my ($self) = @_;

    my @tags_base = @{$self->{tags_base}};
    
    my @tex_lines;
    
    my $cols  = $self->{num_cols};
    my @range = @{$self->{range} || []};

    my $num;
    push @tex_lines, 
        $self->_range_tabular(\@range,$cols);
    
    my $tex = join("\n",@tex_lines);
}

1;
 

