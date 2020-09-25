
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
 

