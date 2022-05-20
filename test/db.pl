#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);
use Base::DB qw(
    dbh_insert_update_hash
    dbh_base2info

    dbi_connect
);

use File::Spec::Functions qw(catfile);
use String::Util qw(trim);

my $img_root = $ENV{IMG_ROOT};
my $repos_git = $ENV{REPOSGIT};

#my $dbfile = catfile($img_root,'img.db');
my $dbfile = catfile($repos_git,qw( p_pc projs.sqlite ));
my $dbh = dbi_connect({ dbfile => $dbfile });

my $b2i = { 'tags' => 'tag' };

my (@tags, @author_id);
push @tags,
 '',
 'two',
 'four',
 ;
push @author_id,
 '',
 'igor',
 'taras',
 ;
  
my $tags = join("," => grep { length } map { trim($_)} @tags);
my $author_id = join("," => grep { length } map { trim($_) } @author_id);
my @files = qw( git.tex git.preamble.tex );

foreach my $file (@files) {
    my $h = {
        tags      => $tags,
        parent    => '',
        author_id => $author_id,
        file      => $file,
    };
    
    dbh_insert_update_hash({
       dbh     => $dbh,
       t       => 'projs',
       h       => $h,
       on_list => [qw( file )],
    });
    
    dbh_base2info({
      'dbfile' => $dbfile,
      'tbase'  => 'projs',
      'bwhere' => { file => $file },
      'jcol'   => 'file',
      'b2i'    => $b2i,
      'bcols'  => [qw( tags author_id )],
    });
}
