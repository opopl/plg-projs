
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
 

