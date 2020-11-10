

package Plg::Projs::Build::Maker::Join;

use strict;
use warnings;

use utf8;

use Data::Dumper qw(Dumper);

use File::Spec::Functions qw(catfile);
use File::Slurp::Unicode;
use File::Path qw(mkpath);

use Plg::Projs::Tex qw(
	q2quotes
);

use File::Dat::Utils qw(readarr);

sub _file_joined {
    my ($mkr) = @_;

    my $jfile = catfile($mkr->{src_dir},'jnd.tex');

    return $jfile;
}

=head3 _join_lines

=head4 Usage

    # $sec  = '_main_'
    # $proj = $m->{proj}
    my @lines = $m->_join_lines();

=cut

sub _join_lines {
    my ($mkr, $sec, $ref) = @_;

    my $bld = $mkr->{bld};

    $ref ||= {};

    $sec = '_main_' unless defined $sec;

    my (@lines, @at_end);

    my (@f_lines);

    my $jfile = $mkr->_file_joined;

    my $file = $ref->{file} || '';

    my $root_id = $mkr->{root_id} || '';
    my $proj    = $ref->{proj} || $mkr->{proj};

    my @include = $mkr->_ii_include;

    my @exclude = $mkr->_ii_exclude;
    
    my $ii_include_all = $mkr->_opt_($ref,'ii_include_all',0);

    my $include_below = $mkr->_val_list_ref_('join_lines include_below');

    my $ss        = $mkr->{sections} || {};

    my $ss_insert = $ss->{insert} || {};
    my $line_sub  = $mkr->_val_('sections line_sub') || sub { shift };

    my $root = $mkr->{root};

    chdir $root;

    mkpath $mkr->{src_dir};

    while(1){
        my $gen = $mkr->_val_('sections generate ' . $sec);
        $gen //= sub { $bld->_gen_sec($sec); };

        if ($gen) {
            if (ref $gen eq 'CODE') {
                my @gen = $gen->();
                if (@gen) {
                    @f_lines = @gen;
                    last;
                }
            }
        }
            
        my $f_sec = $ref->{file} || $mkr->_file_sec($sec,{ proj => $proj });
        if (!-e $f_sec){ return (); }
        @f_lines = read_file $f_sec;

        last;
    }

    my $pats = $mkr->_pats;

    my $delim = '%' x 50;  

    my $r_sec = {
        proj      => $proj,
        sec       => $sec,
        file      => $file,
    };

    my $sect;

    my @prepend = $mkr->_line_plus($sec,'prepend');
    push @lines, @prepend;

    foreach(@f_lines) {
        chomp;

        $_ = $line_sub->($_, $r_sec);

###pat_sect
        m/$pats->{sect}/ && do {
            $sect = $1;

			q2quotes(\$sect);

            $mkr->_line_process_pat_sect({ 
               sect    => $sect,
               root_id => $root_id,
               proj    => $proj,
               sec     => $sec,

               line    => $_,
               lines   => \@lines,
               at_end  => \@at_end,
            });
            
            next;
        };

###pat_input
        m/$pats->{input}/ && do {
            my $fname   = $1;

            $mkr->_line_process_pat_input({ 
                fname         => $fname,
                delim         => $delim,
                include_below => $include_below,

                lines         => \@lines,
                line          => $_,
            });
    
            next;
        };

###pat_ii
        m/$pats->{ii}/ && do {
            my $ii_sec   = $1;

            $mkr->_line_process_pat_ii({ 
                delim          => $delim,

                sect           => $sect,
                ii_sec         => $ii_sec,

                ii_include_all => $ii_include_all,
                include_below  => $include_below,

                lines => \@lines,
                line  => $_,

                proj => $proj,
            });

            next;
        };

###pat_iifig
        m/$pats->{iifig}/ && do {
            my $fig_sec   = 'fig.' . $1;
            my @fig_lines = $mkr->_join_lines($fig_sec,{ proj => $proj });

            push @lines, 
                $delim,
                '%% ' . $_,
                $delim,
                @fig_lines
            ;

            next;
        };

        push @lines, $_;
    }
    push @lines, @at_end;

    my @append = $mkr->_line_plus($sec,'append');
    push @lines, @append;

    if ($sec eq '_main_') {
        write_file($jfile,join("\n",@lines) . "\n");
    }

    return @lines;
}
# end _join_lines

=head3 _ii_include

=head4 Usage

    my @include = $mkr->_ii_include();

=cut

sub _ii_include {
    my ($mkr) = @_;

    my (@include);
    my $f_in = $mkr->_file_ii_include;

    my @i = $mkr->_val_list_(qw( sections include ));
    push @include, @i;

    my $load_dat = $mkr->_val_(qw( load_dat ii_include ));

    while(1){
        last unless $load_dat;
    
        if (-e $f_in) {
            push @include, readarr($f_in);
        }else{
            $mkr->{ii_include_all} = 1;
        }
    
        last;
    }

    $mkr->_ii_include_filter(\@include);

    return @include;
}

=head3 _ii_include_filter

=head4 Usage

    $mkr->_ii_include_filter(\@include);

=head4 Filtering Keywords

    _all_ _base_

=head4 Call tree 

Used in:

    _ii_include

=cut

sub _ii_include_filter {
    my ($mkr, $include) = @_;

    my %i = map { $_ => 1 } @$include;

    my @base = $mkr->_ii_base;

    if ($i{_all_}) {
        $mkr->{ii_include_all} = 1;
        delete $i{_all_};

    }elsif ($i{_base_}) {
        $i{$_} = 1 for(@base);
        delete $i{_base_};
    }

    @$include = sort keys %i;

    return $mkr;
}

sub _ii_exclude {
    my ($mkr) = @_;

    my (@exclude);
    my $f_in = $mkr->_file_ii_exclude;

    my @base = $mkr->_ii_base;

    return @exclude;
}

sub _ii_base {
    my ($mkr) = @_;

    my @base_preamble;
    push @base_preamble,
        map { sprintf('preamble.%s',$_) } 
        qw( index packages acrobat_menu filecontents );

    my @base;
    push @base,
        qw( body preamble index bib ),
        @base_preamble,
        qw( titlepage ),
        qw( defs ),
        qw( listfigs listtabs ),
        qw( tabcont ),
        ;
    return @base;
}

sub _file_ii_exclude {
    my ($mkr) = @_;
            
    catfile(
      $mkr->{root},
      join("." => ( $mkr->{proj}, 'ii_exclude.i.dat' )) 
    );

}

sub _file_ii_include {
    my ($mkr) = @_;
            
    catfile(
      $mkr->{root},
      join("." => ( $mkr->{proj}, 'ii_include.i.dat' )) 
    );

}



1;
 

