

package Plg::Projs::Build::Maker::Join;

use strict;
use warnings;

use utf8;

use Data::Dumper qw(Dumper);

use File::Spec::Functions qw(catfile);
use File::Slurp::Unicode;
use File::Path qw(mkpath);

use File::Dat::Utils qw(readarr);

sub _file_joined {
    my ($self) = @_;

    my $jfile = catfile($self->{src_dir},'jnd.tex');

    return $jfile;
}

=head3 _join_lines

=head4 Usage

    # $sec  = '_main_'
    # $proj = $m->{proj}
    my @lines = $m->_join_lines();

=cut

sub _join_lines {
    my ($self, $sec, $ref) = @_;

    $ref ||= {};

    $sec = '_main_' unless defined $sec;

    my $file = $ref->{file} || '';

    my $root_id = $self->{root_id} || '';
    my $proj    = $ref->{proj} || $self->{proj};

    my @include = $self->_ii_include;

    my @exclude = $self->_ii_exclude;
    
    my $ii_include_all = $ref->{ii_include_all} || $self->{ii_include_all};

    my $jl = $self->{join_lines} || {};
    my $include_below = $ref->{include_below} || $jl->{include_below} || [];

    my $ss        = $self->{sections} || {};

    my $ss_insert = $ss->{insert} || {};
    my $line_sub  = $ss->{line_sub} || sub { shift };

    my $root = $self->{root};

    chdir $root;

    my $jfile = $self->_file_joined;
    mkpath $self->{src_dir};

    my $f = $ref->{file} || $self->_file_sec($sec,{ proj => $proj });

    if (!-e $f){ return (); }

    my @flines = read_file $f;

    my $pats = {
         'ii'    => '^\s*\\\\ii\{(.+)\}.*$',
         'iifig' => '^\s*\\\\iifig\{(.+)\}.*$',
         'input' => '^\s*\\\\input\{(\S+)\}.*$',
         'sect'  => '^\s*\\\\(part|chapter|section|subsection|subsubsection|paragraph)\{.*\}\s*$',
    };

    my $delim = '%' x 50;  

    my $r_sec = {
        proj      => $proj,
        sec       => $sec,
        file      => $file,
    };

    my (@lines, @at_end);
 
    my $sect;

    foreach(@flines) {
        chomp;

        $_ = $line_sub->($_, $r_sec);

###pat_sect
        m/$pats->{sect}/ && do {
            $sect = $1;

            $self->_line_process_pat_sect({ 
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

            $self->_line_process_pat_input({ 
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

            my $iall = $ii_include_all;
            if ($sect) {
                $iall = ( grep { /^$sect$/ } @$include_below ) ? 1 : $iall;
            }

            my $inc = $iall || ( !$iall && grep { /^$ii_sec$/ } @include )
                ? 1 : 0;

            next unless $inc;

            my @ii_lines = $self->_join_lines($ii_sec,{ 
                proj           => $proj,
                ii_include_all => $iall,
                include_below  => $include_below,
            });

            push @lines, 
                $delim,
                '%% ' . $_,
                $delim,
                @ii_lines
            ;

            my $append = $self->_val_('sections append only',$ii_sec);
            if ($append) {
                my $a_lines = $append->() || [];
                push @lines, 
                    '%% append',
                    @$a_lines;
            }

            next;
        };

###pat_iifig
        m/$pats->{iifig}/ && do {
            my $fig_sec   = 'fig.' . $1;
            my @fig_lines = $self->_join_lines($fig_sec,{ proj => $proj });

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

    if ($sec eq '_main_') {
        write_file($jfile,join("\n",@lines) . "\n");
    }

    return @lines;
}

=head3 _ii_include

=head4 Usage

    my @include = $maker->_ii_include();

=cut

sub _ii_include {
    my ($self) = @_;

    my (@include);
    my $f_in = $self->_file_ii_include;

    my @base = $self->_ii_base;

    my @i = @{ $self->_val_(qw( sections include )) || [] };
    push @include, @i;

    my $load_dat = $self->_val_(qw( load_dat ii_include ));
    unless ($load_dat) {
        return @include;
    }

    if (-e $f_in) {
        my @i = readarr($f_in);

        for(@i){
            /^_all_$/ && do {
                $self->{ii_include_all} = 1;
                next;
            };

            /^_base_$/ && do {
                push @include, @base;
                next;
            };

            push @include, $_;
        }
    }else{
        $self->{ii_include_all} = 1;
    }
    return @include;
}

sub _ii_exclude {
    my ($self) = @_;

    my (@exclude);
    my $f_in = $self->_file_ii_exclude;

    my @base = $self->_ii_base;

    return @exclude;
}

sub _ii_base {
    my ($self) = @_;

    my @base_preamble;
    push @base_preamble,
        map { sprintf('preamble.%s',$_) } 
        qw(index packages acrobat_menu filecontents );

    my @base;
    push @base,
        qw(body preamble index bib),
        @base_preamble,
        qw(titlepage),
        qw(listfigs listtabs),
        qw(tabcont),
        ;
    return @base;
}

sub _file_ii_exclude {
    my ($self) = @_;
            
    catfile(
      $self->{root},
      join("." => ( $self->{proj}, 'ii_exclude.i.dat' )) 
    );

}

sub _file_ii_include {
    my ($self) = @_;
            
    catfile(
      $self->{root},
      join("." => ( $self->{proj}, 'ii_include.i.dat' )) 
    );

}



1;
 

