
package Plg::Projs::Build::PdfLatex::IndFile;

=head1 NAME

Plg::Projs::Build::PdfLatex::IndFile

=head1 SEE ALSO

Plg::Projs::Build::PdfLatex

=cut

use strict;
use warnings;

use File::Slurp::Unicode;
use File::Basename qw(basename dirname);

sub ind_ins_bmk {
    my ($self, $ind_file, $level) = @_;

    $ind_file ||= $self->{ind_file};
    $level = $self->{ind_level} unless defined $level;

    unless (-e $ind_file){
        return $self;
    }

   my %ind_items;

   my @out;
   my $theindex=0;
   open(F,"<:encoding(utf-8)", "$ind_file") || die $!;

   my $i=0;
   my $done;

   while(<F>){
       chomp;
       m/%done_ind_ins_bmk/ && do { 
            $done = 1;
       };

       unless ($done) {
		   my $bname = basename($ind_file);

           m/^\\begin\{theindex\}/ && do { $theindex=1; };
           m/^\\end\{theindex\}/ && do { $theindex=0; };

		   my $dest = qq{ind-$bname-$i};

           if($theindex){
    
               m/^\s*\\item\s+(\w+)/ && do { $ind_items{$1} = []; };
        
               m{^\s*\\lettergroup\{(.+)\}$} && do {
                   s{
                       ^\s*\\lettergroup\{(.+)\}$
                   }{
                    \\hypertarget{$dest}{}\n
					\\bookmark[level=$level,dest=$dest]{$1}\n 
                    \\lettergroup{$1}
                   }gmx;
        
                   $i++;
               };
           }

       }

       push @out, $_;

   }
   close(F);
   unshift @out, '%done_ind_ins_bmk';
   write_file($ind_file,join("\n",@out) . "\n");

   return $self;
}

1;
 

