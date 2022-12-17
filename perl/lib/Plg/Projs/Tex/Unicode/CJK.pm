
package Plg::Projs::Tex::Unicode::CJK;

use utf8;
use strict;
use warnings;

use constant MAP => map { $_->{char} => '' } (
  { char => "\N{U+4E66}", name => '' },
  { char => "\N{U+6CD5}", name => '' },
  { char => "\N{U+610F}", name => '' },
  { char => "\N{U+65C5}", name => 'Ideograph trip' },
  { char => "\N{U+884C}", name => 'Ideograph go' },
  #{ char => "\N{<++>}", name => '<++>' },
  #{ char => "\N{<++>}", name => '<++>' },
);

1;
 

