
{
   my @tex;
   push @tex,
     @header,
     pics2tex({ pics => [@pics], cols => $tab_cols, width => $width });
   $OUT .= join("\n" => @tex) . "\n";
}
