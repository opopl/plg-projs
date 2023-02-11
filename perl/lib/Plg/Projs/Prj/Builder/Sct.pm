
package Plg::Projs::Prj::Builder::Sct;

use utf8;

use strict;
use warnings;

use Cwd qw(getcwd);
use String::Util qw(trim);
use Data::Dumper qw(Dumper);

use File::Slurp::Unicode;
use File::Spec::Functions qw(catfile);

use Base::String qw(
    str_split_sn
    str_split_trim
    str_split
);

use Base::Data qw(
    d_str_split_sn
    d_str_split
    d_path
);

use Base::Arg qw(
    varval
    opts2dict
    dict2opts
    dict_update
);

use Base::DB qw(
    dbh_insert_hash
    dbh_select
    dbh_select_first
    dbh_select_as_list
    dbh_select_fetchone
    dbh_do
    dbh_list_tables
    dbh_selectall_arrayref
    dbh_sth_exec
    dbh_update_hash
    dbi_connect

    jcond
);

=head3 _sct_lines

=head4 Usage

    my @lines = $bld->_sct_lines($sec);

=head4 Call tree

    _gen_sec
        _join_lines

=cut

sub _sct_lines {
    my ($bld, $sec) = @_;

    my $mkr = $bld->{maker};
    my $prj = $mkr->{prj};

    my $data      = $bld->_sct_data($sec);
    my $pack_opts = d_path($data,'pkg pack_opts',{});

    #print $bld->_bld_var('pagestyle') . "\n";

    my @lines;

    #my $cref = d_str_split_sn($data,'contents') // [];
    my $cref = d_path($data, 'contents') // [];
    my @contents;
    unless (ref $cref) {
        push @contents, str_split_sn($cref);
    }elsif(ref $cref eq 'ARRAY'){
        push @contents, @$cref;
    }

###loop_CONT
    CONT: while(@contents) {
        local $_ = shift @contents;

        if (ref $_ eq 'HASH') {
            my $ccc = $_;
            my $type = $ccc->{type};

            # final result
            my @pic_content;

            if ($type eq 'sql') {
                my ($db, $query, $params) = @{$ccc}{qw( db query params )};
                next CONT unless $db && $query;
                $params ||= [];

                my ($output, $cmt) = @{$ccc}{qw( output cmt )};
                my (@begin, @end);

                my $dbx;
                if ($db eq 'img') { $dbx = $bld->{imgman}->{dbh}; }
                my $ref = {
                    dbh => $dbx,
                    q => $query,
                    p => $params,
                };
                my ($rows) = dbh_select($ref);
                next CONT unless $rows && @$rows;
                my $amount = scalar @$rows;

                if ($cmt) {
                    push @begin, '\ifcmt';
                    push @end, '\fi';

                    AMOUNT: while(1){
                        if ($amount == 1) {
                            my $rw = shift @$rows;
                            my ($url, $caption) = @{$rw}{qw( url caption )};
                            my $opts = varval('single.opts', $cmt) || {};
                            my $indent = ' ' x 3;
                            push @pic_content,
                                sprintf('%s ig %s', $indent, $url),
                                $caption ? sprintf('%s @caption %s', $indent, $caption) : (),
                                ( map { sprintf('%s %s %s', $indent, $_, $opts->{$_}) } keys %$opts ),
                                ;
                            last AMOUNT;
                        }

                        my $tab = $cmt && ref $cmt eq 'HASH' && $cmt->{tab};
                        if ($tab) {
                            my $tab_s;
                            $tab_s = !ref $tab ? $tab : '';
                            my $tab_dict = opts2dict($tab_s) || {};
                            unless($tab_s){
                                if(ref $tab eq 'ARRAY'){
                                    foreach my $x (@$tab) {
                                        unless(ref $x){
                                            my $d = opts2dict($x);
                                            dict_update($tab_dict, $d) if $d;
                                        } elsif(ref $x eq 'ARRAY'){
                                            for(@$x){
                                                my $d = opts2dict($_);
                                                dict_update($tab_dict, $d) if $d;
                                            }
                                        } elsif(ref $x eq 'HASH'){
                                            dict_update($tab_dict, $x);
                                        }
                                    }
                                }elsif(ref $tab eq 'HASH'){
                                    dict_update($tab_dict, $tab);
                                }
                            }

                            $tab_dict->{cols} = $amount if $amount < $tab_dict->{cols};
                            $tab_dict->{amount} = $amount;
                            $tab_s = dict2opts($tab_dict);

                            push @begin, sprintf(' tab_begin %s',$tab_s);
                            unshift @end, ' tab_end';
                        }

                        last AMOUNT;
                    }
                }

                foreach my $rw (@$rows) {
                    ( my $fin = $output ) =~ s|@@\{(\w+)\}|( $rw->{$1} // '' )|ge;
                    push @pic_content, $fin;
                }

                if (@pic_content) {
                    push @lines, @begin, @pic_content, @end;
                }
            }
            next;
        }else{
            my @s = str_split_sn($_);
            if (@s > 1) {
                unshift @contents, @s;
                next;
            }
        }
###@zero
        /^\@zero$/ && do {
            push @lines,'';
            next;
        };
###@doc
        /^\@doc$/ && do {
            my $doc   = d_path($data,'doc');

            my $opts  = $doc->{opts} || '';
            my $class = $doc->{class} || '';

            my $o = $opts ? qq{[$opts]} : '';

            local $_ = sprintf('\documentclass%s{%s}',$o,$class);
            push @lines,$_;
            next;
        };
###@setcounter
        /^\@setcounter$/ && do {
            my $stc = d_path($data,'setcounter');
            while(my($k,$v)=each %$stc){
                local $_ = sprintf('\setcounter{%s}{%s}',$k,$v);
                push @lines,$_;
            }

            next;
        };
###@ii
        /^\@ii(?:|\.(.*))$/ && do {
            my $p = $1 // '';
            $p =~ s/\./ /g;

            my $path = 'ii ' . $p;

            my $ii_list = d_path($data,$path,[]);
            #my @ii = d_str_split_sn($data,$path);
            my @ii = $bld->_sct_ii_expand($ii_list);

            foreach my $ii_sec (@ii) {
              push @lines, sprintf('\ii{%s}',$ii_sec);
            }
            next;
        };
###@input
        /^\@input$/ && do {
            my @input = d_str_split_sn($data,'input');
            foreach my $sec (@input) {
                local $_ = sprintf('\input{%s}',$sec);
                push @lines,$_;
            }
            next;
        };
###@makeindex
        /^\@makeindex$/ && do {
            push @lines, $bld->_bld_ind_makeindex;

            next;
        };
###@printindex
        /^\@printindex$/ && do {
#            my @pi_lines = $bld->_bld_ind_printindex;

            #my $mkr      = $bld->{maker};
            #my $pi_file  = catfile($mkr->{src_dir},qw(print_index.tex));

            #write_file($pi_file,join("\n",@pi_lines) . "\n");

            push @lines, q|\InputIfFileExists{print_index.tex}{}{}|;

            next;
        };
###@perl
        /^\@perl$/ && do {
            my $pl = d_path($data,'perl');
            my @w;
            local $SIG{__WARN__} = sub { push @w,@_; };
            my $res = eval $pl;
            if ($@){
                warn $@ . "\n";
            }
            push @lines, $res;
            next;
        };
        /^\@perlfile\{(.*)\}$/ && do {
            my $pl = $1;
            if (-e $pl) {
                my $res = do $pl;
                push @lines, $res;
            }
            next;
        };
###@pkg
        /^\@pkg$/ && do {
            my @pack_list = d_str_split_sn($data,'pkg pack_list');
            foreach my $pack (@pack_list) {
                next unless $pack;

                my $s_o = $pack_opts->{$pack} || '';
                my @o = str_split_sn($s_o);

                $s_o = join(',' => @o);

                my $o = $s_o ? qq{[$s_o]} : '';

                local $_ = sprintf('\usepackage%s{%s}',$o,$pack);

                push @lines,$_ if length;
            }
            next;
        };
###@txt
        /^\@txt(?:|\.(.*))$/ && do {
            my $p = $1 // '';
            $p =~ s/\./ /g;

            my @txt = d_str_split($data,'txt ' . $p );
            $bld->_txt_expand({ txt_lines => \@txt });
            push @lines, @txt;

            next;
        };

        $bld->_txt_expand({ txt_ref => \$_ });
        push @lines,$_;

    }
    return @lines;

}

sub _bld_env {
    my ($bld, $var) = @_;

    my $val = $ENV{$var} || '';
    return $val;
}

sub _sct_ii_expand {
    my ($bld, $ii_list) = @_;
    $ii_list ||= [];

    my $mkr = $bld->{maker};
    my $prj = $mkr->{prj};

    my @ii;

    foreach my $ii_sec (@$ii_list) {
        unless(ref $ii_sec){
           push @ii, $ii_sec;
        }
        elsif (ref $ii_sec eq 'HASH') {
           my ($sql, $select, $shell)    = @{$ii_sec}{qw(sql select shell)};

###@ii_shell
           $shell && do {
              unless (ref $shell) {
                 my @list = qx{$shell};
                 my @iish;
                 for(@list){
                     chomp;
                     next unless length $_;

                     /^\\ii\{(\S+)\}\s*$/ && do { push @iish, $1; next; };

                     push @iish, $_;
                 }
                 push @ii, @iish;
              }
           };

###@ii_sql
           $sql && do {
              unless (ref $sql) {
              }elsif(ref $sql eq 'HASH'){
                 my $query  = $sql->{query} || '';
                 my $params = $sql->{params} || [];
                 my $ref = {
                     dbfile  => $mkr->{dbfile},
                     q       => $query,
                     p       => $params,
                 };
                 my $list = dbh_select_as_list($ref);
                 push @ii, @$list;
              }
           };

###@ii_select
           $select && do {
              my $list = [];

              unless (ref $select) {

              }elsif(ref $select eq 'HASH'){
                 push @$list, $prj->_secs_select($select);
              }

              push @ii, @$list;
              1;
           };
        }
    }

    wantarray ? @ii : \@ii;
}

sub _sct_data {
    my ($bld, $sec) = @_;

    my ($scts, @data, $data);

    $scts = $bld->_val_('sii scts') || [];
    if (ref $scts eq 'HASH') {
        $data = $scts->{$sec};

    } elsif (ref $scts eq 'ARRAY') {
        @data = map { $_->{name} eq $sec ? $_ : () } @$scts;

        foreach my $x (@data) {
            while(my($k,$v) = each %$x){
                $data->{$k} = $v;
            }
        }
    }

    return $data;
}

1;


