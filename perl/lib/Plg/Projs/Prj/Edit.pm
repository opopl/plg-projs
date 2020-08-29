
package Plg::Projs::Prj::Edit;

use strict;
use warnings;

use base qw(
    Plg::Projs::Prj
);

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use utf8; 
use Encode;
binmode STDOUT, ":utf8";

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    my $h = {
        subs => {
            edit_line    => '',
            process_file => '',
        }
    };
        
    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

    return $self;
}

sub edit_tex {
    my ($self) = @_;

    my $root = $self->{root};
    my $proj = $self->{proj};

    my $files = $self->{files}->{tex} || [];

    my $sub_file = $self->{subs}->{process_file};
    my $sub_line = $self->{subs}->{edit_line};

    foreach my $f (@$files) {
        my $file = catfile($root, $f);

        my ($sec) = ($f =~ m/^$proj\.(.*)\.tex$/);

        my $r_file = { 
            root  => $root,
            proj  => $proj,
            file  => $file,
            sec   => $sec,
            f     => $f,
        };

        $r_file = $sub_file->($r_file) if $sub_file;

        unless (-e $file) {
            warn sprintf( 'NO FILE: %s', $file ) . "\n";
            next;
        }

        my @lines = read_file($file);
        my @nlines;

        foreach(@lines) {
            chomp;

            $_ = $sub_line->($_, $r_file ) if $sub_line;

            push @nlines, $_;
        }

        write_file($file,join("\n",@nlines) . "\n");
    }

    return $self;
}


sub run {
    my ($self) = @_;

    my $root = $self->{root};
    my $proj = $self->{proj};

    $self
        ->fill_files
        ->edit_tex
        ;

    return $self;
}



1;
 

