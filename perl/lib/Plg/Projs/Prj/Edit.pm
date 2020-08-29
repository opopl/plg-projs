
package Plg::Projs::Prj::Edit;

use strict;
use warnings;

use base qw(
    Plg::Projs::Prj
);

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);
use Data::Dumper qw(Dumper);

use utf8; 
use Encode;
binmode STDOUT, ":utf8";

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    my $h = { 
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

	my $subs = $self->{subs} || {};

    my $sub_file = $subs->{process_file};
    my $sub_line = $subs->{edit_line};

    foreach my $row (@$files) {
		my $file   = $row->{file};
		my $sec    = $row->{sec};

        my $file_path = catfile($root, $file);

        my $r_file = { 
            root      => $root,
            proj      => $proj,
            sec       => $sec,
            file      => $file,
            file_path => $file_path,
        };

        $r_file = $sub_file->($r_file) if $sub_file;

        unless (-e $file) {
            warn sprintf( 'NO FILE: %s', $file ) . "\n";
            next;
        }

        my @lines = read_file($file);
        my @nlines;

		my $r_run = {};
        foreach(@lines) {
            chomp;

            $_ = $sub_line->($_, $r_file, $r_run ) if $sub_line;

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
 

