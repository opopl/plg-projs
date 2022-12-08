
package Plg::Projs::Tex::Unicode::Japanese;

use utf8;
use strict;
use warnings;

use constant MAP => map { $_->{char} => '' } (
  { char => "\N{U+30A2}", name => 'Katakana Letter A' },
  { char => "\N{U+30EC}", name => 'Katakana Letter Re' },
  { char => "\N{U+30C3}", name => 'Katakana Letter Small Tu' },
  { char => "\N{U+30AF}", name => 'Katakana Letter Ku' },
  { char => "\N{U+30B9}", name => 'Katakana Letter Su' },
  #{ char => "\N{<++>}", name => '<++>' },
);

1;
 
