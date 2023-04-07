
{
   my @tex;
   push @tex,
     @header,
     pics2tex({
          pics => [@pics],
          cols => $tab_cols,
          width => $width,
          add_layout => 1,
          split => 1,
     });
   $OUT .= join("\n" => @tex) . "\n";
}
