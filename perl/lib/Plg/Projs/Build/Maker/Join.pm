

package Plg::Projs::Build::Maker::Join;

use strict;
use warnings;

use utf8;

use YAML qw( LoadFile Load Dump DumpFile );


use Data::Dumper qw(Dumper);

use File::Spec::Functions qw(catfile);
use File::Slurp::Unicode;
use File::Path qw(mkpath);

use Plg::Projs::Tex qw(
    texify
);

use Base::String qw(
    str_split
    str_split_sn
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

###jlines
sub _join_lines {
    my ($mkr, $sec, $ref) = @_;

    my $bld = $mkr->{bld};

    $ref ||= {};

    $sec = '_main_' unless defined $sec;

    my (@lines, @at_end);

    my (@f_lines);

    my $jfile = $mkr->_file_joined;

    my $file = $ref->{file} || '';

    my $root    = $mkr->{root};
    my $root_id = $mkr->{root_id} || '';
    my $proj    = $ref->{proj} || $mkr->{proj};

    my @include = $mkr->_ii_include;

    my @exclude = $mkr->_ii_exclude;
    
    my $ii_include_all = $mkr->_opt_($ref,'ii_include_all',0);

    my $include_below = $mkr->_val_list_ref_('join_lines include_below');

    my $ss        = $mkr->{sections} || {};

    my $ss_insert = $ss->{insert} || {};
    my $line_sub  = $mkr->_val_('sections line_sub') || sub { shift };

    chdir $root;

    mkpath $mkr->{src_dir};

    $file ||= $mkr->_file_sec($sec,{ proj => $proj });

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
            
        return () unless -f $file; 
        @f_lines = read_file $file;

        last;
    }

    my $pats = $mkr->_pats;

    my $delim = '%' x 50;  

    my ($date) = ( $sec =~ m/^(\d+_\d+_\d+)\..*$/ );
    my $prj = $mkr->{prj};
    my $sd = $prj->_sec_data({
        sec  => $sec,
        proj => $proj,
    });
    while(my($k,$v)=each %$sd){
        $sd->{$k} = '' unless defined $sd->{$k};
    }

    my $r_sec = {
        %$sd,
        proj   => $proj,
        sec    => $sec,
        file   => $file,
        date   => $date,
    };
    $mkr->{r_sec} = $r_sec;

    my $sect;

    my @prepend = $mkr->_line_plus($sec,'prepend');
    push @lines, @prepend;

    $mkr->tree_init({ sec => $sec });
    my %flg;
    my @yaml;

###for_@f_lines
    foreach(@f_lines) {
        chomp;

        /^%%beginhead/ && do { $flg{head} = 1; next; };
        /^%%endhead/ && do { $flg{head} = undef; next; };
        next if $flg{head};
        next if /^%\s+vim:/;

        unless ($flg{yaml}) {
            my $ystr = Dump($r_sec);
            push @yaml,
                '\ifcmt',
                ' yaml_begin',
                $ystr,
                ' yaml_end',
                '\fi';
            push @lines, @yaml;
            $flg{yaml} = 1;
        }

        $_ = $line_sub->($_, $r_sec);

###pat_sect
        m/$pats->{sect}/ && do {
            $sect = $1;
            my $title = $2;
            #texify(\$title);
            my $title_tex = texify($title);

            $mkr->{r_sec}->{title} = $title;

            s|$pats->{sect}|\\$1\{$title_tex\}|g;

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

            $mkr
                ->tree_init({ sec => $ii_sec })
                ->tree_add_parent({ sec => $ii_sec, parent => $sec })
                ->tree_add_child({ sec => $sec, child => $ii_sec })
                ;

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

    if ( $sec eq '_main_' && !$ref->{skip_write} ) {
        write_file($jfile,join("\n",@lines) . "\n");
    }

    return @lines;
}
# end _join_lines
#

sub _ii_only {
    my ($mkr) = @_;

    my @ii_only;

    return @ii_only;
}

sub _ii_include {
    my ($mkr) = @_;

    my $iii = $mkr->{ii_include};
    if($iii && (ref $iii eq 'ARRAY') && @$iii){
        return @$iii;
    }
    return ();
}

=head3 ii_filter

=head4 Usage

    $mkr->ii_filter(\@include);

=head4 Filtering Keywords

    _all_ _base_

=head4 Call tree 

Used in:

    init_ii_include

=cut

sub ii_filter {
    my ($mkr, $include) = @_;

    $include ||= $mkr->{ii_include};

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

#called by init_ii_include
sub ii_insert_updown {
    my ($mkr, $include) = @_;

    $include ||= $mkr->{ii_include};

    my (%i, %i_updown, %i_base);

    %i_base = map { $_ => 1 } $mkr->_ii_base;

    my $bld = $mkr->{bld};
    return $mkr unless $bld;

    my $ii_updown = $bld->_bld_var('ii_updown') || '';

    return $mkr unless ($ii_updown);
    $mkr
        ->tree_import
        #->tree_dump
        ;

    my (@updown, @up, @down);
    if(ref $ii_updown eq 'ARRAY'){
        @updown = @$ii_updown;
    }elsif(!ref $ii_updown){
        @updown = str_split_sn($ii_updown);
    }

    my $j = 0;
    while (1) {
        my $s = shift @updown;

        $i_updown{$s} = 1;

        my (@parents, @children);

        @parents  = @{$mkr->_tree_sec_get($s,'parents') || []};
        @children = @{$mkr->_tree_sec_get($s,'children') || []};

        while(@parents){
            my $par = shift @parents;

            $i_updown{$par} = 1;

            push @parents,@{$mkr->_tree_sec_get($par,'parents') || []};
        }

        while(@children){
            my $cld = shift @children;

            $i_updown{$cld} = 1;

            push @children,@{$mkr->_tree_sec_get($cld,'children') || []};
        }

        last unless @updown;
        #last if $j==100;
        $j++;
    }
    %i = ( %i_updown, %i_base );

    @$include = sort keys %i;
    delete $mkr->{join_lines}->{include_below};

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

    my $bld  = $mkr->{bld};
    return () unless $bld;

    my $v    = $bld->_bld_var('ii_base');
    my @base = str_split_sn($v);

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
 

