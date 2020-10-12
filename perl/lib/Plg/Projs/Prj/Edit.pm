
package Plg::Projs::Prj::Edit;

use utf8; 

use Encode;
binmode STDOUT, ":utf8";
use open ':std', ':encoding(utf8)';


use strict;
use warnings;

use base qw(
    Plg::Projs::Prj
);

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);
use Data::Dumper qw(Dumper);

use Base::Arg qw( hash_update );


sub init {
    my ($self) = @_;

    $self->SUPER::init();

    my $h = { 
    };
        
    hash_update($self, $h, { keep_already_defined => 1 });

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

        $r_file = $self->_sub('process_file', $r_file);

        unless (-e $file) {
            warn sprintf( 'NO FILE: %s', $file ) . "\n";
            next;
        }

        my @lines = read_file($file);
        my @nlines;

        my $r_run = {};
        foreach(@lines) {
            chomp;

            $_ = $self->_sub('edit_line', $_, $r_file, $r_run );

            push @nlines, $_;
        }

        write_file($file,join("\n",@nlines) . "\n");
    }

    return $self;
}

sub _sub_edit_line_replace {
    my $self = shift;

    local $_ = shift;

    s/(\s+)–(\s+)/$1---$2/g;
    s/(\s+)—(\s+)/$1---$2/g;

    s/(\d+)—(\d+)/$1-$2/g;
    s/(\d+)–(\d+)/$1-$2/g;

    s/^—(\s+)/---$1/g;
    s/(\s+)—(\s+)/$1---$2/g;
    s/(\d+)—(\d+)/$1-$2/g;

    s/^─(\s+)/---$1/g;
    s/(\s+)─\s*$/$1---/g;
    s/(\s+)─(\s+)/$1---$2/g;
    s/(\d+)─(\d+)/$1-$2/g;

    s/^\s*\\(chapter|section|subsection|subsubsection|paragraph)\{"(.*)"\}/\\$1\{\\enquote{$2}\}/g;

    return $_;
}


sub _sub {
    my ($self, $sub, @args) = @_;

    my $meth = sprintf(q{_sub_%s},$sub);
    $self->$meth(@args) if $self->can($meth);
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
 

