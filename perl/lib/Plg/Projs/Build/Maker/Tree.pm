
package Plg::Projs::Build::Maker::Tree;

use strict;
use warnings;
use utf8;

use File::Spec::Functions qw(catfile);

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
            $prop = $1;
            $tree->{$prop} ||= [];

            next;
        };

        /^\t\t(\S+)$/ && do {
            my $sc = $1;
            push @{$tree->{$prop}}, $sc;
            next;
        };
    }

    $mkr->{ii_tree} = $tree;

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
 

