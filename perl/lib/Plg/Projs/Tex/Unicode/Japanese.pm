
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
  { char => "\N{U+30FB}", name => 'Katakana Middle Dot' },
  { char => "\N{U+30AD}", name => 'Katakana Letter Ki' },
  { char => "\N{U+30A8}", name => 'Katakana Letter E' },
  { char => "\N{U+30D5}", name => 'Katakana Letter Hu' },
  #{ char => "\N{<++>}", name => '<++>' },
);

1;
 
