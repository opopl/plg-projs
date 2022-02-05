
package Plg::Projs::Prj::Builder::Sct::yml_select;

use strict;
use warnings;

#from Sct.pm
#$select && do {
                      #unless (ref $select) {
                      #}elsif(ref $select eq 'HASH'){
                          ##my $where = $select->{where} || {};
                          ##

                          #my (%wh, %conds, %tbls);
                          #my (@cond, @params);
                          #my @ij;

                          #my @keys = qw(tags author_id);
                          #my %key2col = (
                             #'tags' => 'tag'
                          #);
                          #foreach my $key (@keys) {
                              #my $wk = $wh{$key} = $select->{$key};
                              #next unless $wk;

                              #my $colk = $key2col{$key} || $key;
                              
                              #my (@pk, $tk, @ck);
                              #$tk = '_info_projs_' . $key;
    
                              #if (ref $wk eq 'HASH') {
                                  #foreach my $op (qw( or and )) {
                                      #my @ck_op;

                                      #my $vals = $wk->{$op};
                                      #next unless $vals;
                                      #next unless ref $vals eq 'ARRAY';

                                      #my $opj = sprintf(' %s ',uc $op);
                                      #push @ck_op, map { sprintf('%s.%s = ? ', $tk, $colk) } @$vals;
                                      #push @pk, @$vals;

                                      #push @ck, join $opj => @ck_op;
                                  #}
                              #} elsif (ref $wk eq 'ARRAY') {
                                 #next unless @$wk;

                                 #my @ck_or;

                                 #my $vals = $wk;
                                 #my $opj = ' OR ';
                                 #push @ck_or, map { sprintf('%s.%s = ? ', $tk, $colk) } @$vals;
                                 #push @ck, join $opj => @ck_or;
                                 #push @pk, @$vals;
                              #}

                              #push @ij, { on => 'file', tbl => $tk } if @pk;
                              #push @params, @pk;

                              #$conds{$key} = @ck > 1 ? join(' AND ' => map { '( ' . $_ . ' )' } @ck) : shift @ck;
                          #}
                          #push @cond, join " AND " => map { $conds{$_} ? '( ' . $conds{$_} . ' )' : () } @keys;
                          #unshift @cond, 'WHERE ' if @cond;

                          #my $ref = {
                              #dbfile  => $mkr->{dbfile},
                              #t => 'projs',
                              #f => [qw(sec)],
                              #ij => \@ij,
                              #p => \@params,
                              #cond => join(" ",@cond),
                          #};
                          #my $list = dbh_select_as_list($ref);
                          #1;
                      #}
                   #};

1;
 

