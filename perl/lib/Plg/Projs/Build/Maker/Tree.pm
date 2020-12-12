
package Plg::Projs::Build::Maker::Tree;

use strict;
use warnings;
use utf8;

use File::Spec::Functions qw(catfile);
use File::Slurp::Unicode;
use Data::Dumper qw(Dumper);

binmode STDOUT,':encoding(utf8)';

sub _file_tree {
    my ($mkr) = @_;

    my $file_tree = catfile($mkr->{root},$mkr->{proj} . '.tree');
    return $file_tree;
}

sub tree_init {
    my ($mkr,$ref) = @_;
    $ref ||= {};

    my $sec = $ref->{sec} || '';
    if ($sec) {
        $mkr->{ii_tree}->{$sec} ||= {};
        $mkr->{ii_tree}->{$sec}->{children} ||= [];
        $mkr->{ii_tree}->{$sec}->{parents} ||= [];
    }

    return $mkr;
}

sub _tree_sec_get {
    my ($mkr, $sec, $key) = @_;

	my $s_data = $mkr->{ii_tree}->{$sec} || {};

	my $k_data = $s_data->{$key};

    return $k_data;
}

sub tree_import {
    my ($mkr, $ref) = @_;
    $ref ||= {};

    my $file_tree = $mkr->_file_tree;
    my @lines     = read_file $file_tree;

    my $tree = {};

    my ($sec, $prop);
    while (@lines) {
        local $_ = shift @lines;

        /^(\S+)$/ && do {
            $sec = $1;
            $tree->{$sec} ||= {};
            $prop = undef;

            next;
        };

        /^\t(\w+)$/ && do {
			next unless ( $sec && $tree->{$sec} );

            $prop = $1;
            $tree->{$sec}->{$prop} ||= [];

            next;
        };

        /^\t\t(\S+)$/ && do {
			next unless ( $sec && $tree->{$sec} );

            my $sc = $1;
            push @{$tree->{$sec}->{$prop}}, $sc;
            next;
        };
    }

    $mkr->{ii_tree} = $tree;

    return $mkr;
}

sub tree_dump {
    my ($mkr,$ref) = @_;
    $ref ||= {};

	print Dumper($mkr->{ii_tree}) . "\n";

    return $mkr;
}

sub tree_write {
    my ($mkr,$ref) = @_;
    $ref ||= {};

    my $file_tree = $mkr->_file_tree;
    my $tree = $mkr->{ii_tree} || {};

    my $proj    = $mkr->{proj};
    my $root_id = $mkr->{root_id};

    my @lines;
    foreach my $sec (sort keys %$tree) {
        next unless $sec;

        push @lines, $sec;

        my $d = $tree->{$sec};
        foreach my $k (qw( parents children )) {
            my $a = $d->{$k};
            next unless $a;
            if (ref $a eq 'ARRAY') {
                push @lines, 
                    "\t" . $k,
                    map { "\t\t" . $_ } @$a;
            }
        }
    }

    write_file($file_tree,join("\n",@lines) . "\n");

    return $mkr;
}

sub tree_fill {
    my ($mkr,$ref) = @_;
    $ref ||= {};

    # this will fill in $mkr->{ii_tree} object
    $mkr->_join_lines('_main_',{ 
        ii_include_all => 1,
        skip_write     => 1,
    });

    return $mkr;
}

sub tree_add_child {
    my ($mkr,$ref) = @_;
    $ref ||= {};

    my $sec    = $ref->{sec} || '';
    my $child  = $ref->{child} || '';

    if ($sec && $child) {
        $mkr->tree_init({ sec => $sec });
        push @{ $mkr->{ii_tree}->{$sec}->{children} }, $child;
    }

    return $mkr;
}

sub tree_add_parent {
    my ($mkr,$ref) = @_;
    $ref ||= {};

    my $sec    = $ref->{sec} || '';
    my $parent = $ref->{parent} || '';

    if ($sec && $parent) {
        $mkr->tree_init({ sec => $sec });
        push @{ $mkr->{ii_tree}->{$sec}->{parents} }, $parent;
    }

    return $mkr;
}


1;
 

