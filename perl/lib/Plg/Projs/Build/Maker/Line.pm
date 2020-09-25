
package Plg::Projs::Build::Maker::Line;

use strict;
use warnings;
use Data::Dumper qw(Dumper);

=head3 _line_process_pat_sect

    Used in 
    Plg::Projs::Build::Maker::Join
        _join_lines

=cut 

sub _line_process_pat_sect {
    my ($self,$ref) = @_;

    $ref ||= {};

    my $root_id = $ref->{root_id} || $self->{root_id};
    my $proj    = $ref->{proj} || $self->{proj};

    # section name inside \section{...}
    my $sect = $ref->{sect} || '';

    my $line = $ref->{line} || '';

	# inside \ii{...}
    my $sec = $ref->{sec} || '';

    my $lines  = $ref->{lines} || [];
    my $at_end = $ref->{at_end} || [];

    # see Plg::Projs::Prj::Builder::Insert
    my @ins_order = $self->_val_list_('sections ins_order');

    my $r = {
        sect      => $sect,
    };

    push @$lines, 
        $line,
        $self->_debug_sec($root_id, $proj, $sec)
        ;

    foreach my $ord (@ins_order) {
        my $ss    = $self->_val_('sections insert',$ord) || [];

        foreach my $sss (@$ss) {
            my $scts      = $sss->{scts} || [];
            my $sss_lines = $sss->{lines} || [];
   
            my $ins = 0;
            if (@$scts) {
                $ins = (@$scts && grep { /^$sect$/ } @$scts) ? 1 : 0;
            }
   
            if ($ins) {
                my @a = (ref $sss_lines eq 'ARRAY') ? @$sss_lines : $sss_lines->($r);
                push @$lines, @a;

                if ($ord eq 'titletoc') {
                    push @$at_end, @{ $sss->{lines_stop} || [] };
                }
            }
   
        }

    }

    return $self;

}

sub _line_process_pat_ii {
    my ($self,$ref) = @_;

    $ref ||= {};

    my $ii_sec = $ref->{ii_sec} || '';
    my $sect   = $ref->{sect} || '';

    my $proj   = $ref->{proj} || '';

    my $delim  = $ref->{delim} || '';

    my $lines         = $ref->{lines} || [];
    my $include_below = $ref->{include_below} || [];
    my $line          = $ref->{line} || '';

    my $ii_include_all = $ref->{ii_include_all};

    my @include = $self->_ii_include;

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

    push @$lines, 
        $delim,
        '%% ' . $line,
        $delim,
        @ii_lines
    ;

    my $append = $self->_val_('sections append only',$ii_sec);
    if ($append) {
        my $a_lines = $append->() || [];
        push @$lines, 
            '%% append',
            @$a_lines;
    }


    return $self;
}


sub _line_process_pat_input {
    my ($self,$ref) = @_;

    $ref ||= {};

    my $fname         = $ref->{fname} || '';
    my $include_below = $ref->{include_below} || [];

    my $delim         = $ref->{delim} || '';

    my $line   = $ref->{line} || '';
    my $lines  = $ref->{lines} || [];

    my @files;
    push @files,
        $fname, qq{$fname.tex};

    while (@files) {
        my $file = shift @files;

        next unless -e $file;

        my ($proj) = ($file =~ m/^(\w+)\./);

        my @ii_lines = $self->_join_lines('',{ 
            proj           => $proj,
            file           => $file,
            ii_include_all => 1,
            include_below  => $include_below,
        });

        push @$lines, 
            $delim, '%% ' . $line, $delim,
            @ii_lines
            ;

    }

    return $self;
}

1;
 

