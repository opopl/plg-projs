
package Plg::Projs::Tex::Unicode::Japanese;

use utf8;
use strict;
use warnings;

use constant MAP => map { $_->{char} => '' } (
  { char => "\N{U+30A2}", name => 'Katakana Letter A' },
  #{ char => "\N{<++>}", name => '<++>' },
);

1;
 
