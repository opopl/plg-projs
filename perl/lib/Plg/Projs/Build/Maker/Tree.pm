
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


1;
 

