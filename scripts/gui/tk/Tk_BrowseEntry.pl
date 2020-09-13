#!/usr/bin/env perl 
#
#https://docstore.mik.ua/orelly/perl3/tk/ch23_06.htm

use strict;
use warnings;
use utf8;

use Data::Dumper qw(Dumper);

use Tk;                                                                                 
use Tk::ROText;                                                                         
use Tk::BrowseEntry;                                                                    

my $mw = MainWindow->new(-title => "Text search using BrowseEntry");                       
my %searches;
                                                                                         
# Create Browse Entry to enter search text in, and save off                             
# already entered text that you've searched for.                                        
my $f = $mw->Frame(-relief => 'ridge', -borderwidth => 2)                                  
   ->pack(-fill => 'x');                                                                 

# Use ROText so user can't change speech                                                
my $t = $mw->Scrolled('ROText', -scrollbars => 'osoe')                                     
    ->pack(-expand => 1, -fill => 'both');                                                
                                                                                         
my $s = q{                                                           
 "Give Me Liberty or Give Me Death"                                                      
 March 23, 1775                                                                          
 By Patrick Henry                                                                        
 No man thinks more highly than I do of the patriotism, as well as abilities, of the     
 very worthy gentlemen who have just addressed the house. But different                  
 <snipped...> I                                                                          
 know not what course others may take; but as for me, give me liberty or give me death!  
};

$t->insert('end', $s); 
                                                                                         
# define a new tag to use on selected text                                              
# (making it look just like normal selection)                                           
# This way the Text widget doesn't need focus to show selection                         
$t->tagConfigure('curSel', -background => $t->cget(-selectbackground),                  
                   -borderwidth => $t->cget(-selectborderwidth),                         
                   -foreground => $t->cget(-selectforeground));                          
                                                                                         
my $search_string = "";                                                                 
                                                                                         
# If user selects item from list manually, invoke do_search                             
my $be = $f->BrowseEntry(-variable => \$search_string,                                     
                       -browsecmd => \&do_search)->pack(-side => 'left');                
 # If user types in word and hits return, invoke do_search                               
 $be->bind("<Return>", \&do_search);                                                     
 $be->focus;  # Start w/focus on BrowseEntry                                             
                                                                                         
 # Clicking the Search button will invoke do_search                                      
 $f->Button(-text => 'Search', -command => \&do_search)                                  
     ->pack(-side => 'left');                                                            
 $f->Button(-text => 'Exit', -command => \&do_exit)                                      
     ->pack(-side => 'right');                                                           
                                                                                         
 sub do_search {                                                                         
   # Add search string to list if it's not already there                                 
   if (! exists $searches{$search_string}) {                                             
     $be->insert('end', $search_string);                                                 
   }                                                                                     
   $searches{$search_string}++;                                                          
                                                                                         
   # Calculate where to search from, and what to highlight next                          
   my $startindex = 'insert';                                                            
   if (defined $t->tagRanges('curSel')) {                                                
     $startindex = 'curSel.first + 1 chars';                                             
   }                                                                                     
   my $index = $t->search('-nocase', $search_string, $startindex);                       
   if ($index) {                                                                   
     $t->tagRemove('curSel', '1.0', 'end');                                              
     my $endindex = "$index + " .  (length $search_string) . " chars";                   
     $t->tagAdd('curSel', $index, $endindex);                                            
     $t->see($index);                                                                    
   } else { $mw->bell; }                                                                 
                                                                                         
   $be->selectionRange(0, 'end'); # Select word we just typed/selected                   
 }                                                                                       
                                                                                         
 # print stats on searching before we exit.                                              
 sub do_exit {                                                                           
   print "Count  Word\n";                                                                
   foreach (sort keys %searches) {                                                       
     print "$searches{$_}        $_\n";                                                  
   }                                                                                     
   exit;                                                                                 
 }                                                                                       
                                                                                         
MainLoop;                                                                               

