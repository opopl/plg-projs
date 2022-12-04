
package Plg::Projs::Prj::Builder::Plan;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

use Data::Dumper qw(Dumper);

use Capture::Tiny qw(capture);
use Clone qw(clone);

use JSON::XS;
use File::Spec::Functions qw(catfile);
use File::stat;

use Base::Arg qw(
   dict_exe_cb
   dict_update
);

my $plan_stat = {};

sub run_plans {
    my ($bld, $ref) = @_;
    $ref ||= {};

    my $proj = $bld->{proj};

    my $mkr = $bld->{maker};

    my $plans    = $ref->{plans} || $bld->{plans} || {};
    my $plan_seq = clone( $ref->{plan_seq} || $plans->{seq} || [] );

    my $define = clone( $plans->{define} || {} );

    my ($def_dict, $def_order) = $bld->_obj2dict_order($define);
    $DB::single = 1;

    while(@$plan_seq) {
        my $plan_name = shift @$plan_seq;

        my $plan_def = {};

        #print Dumper($define) . "\n";
        #print Dumper($def_dict) . "\n";
        #print Dumper($def_order) . "\n";
        #print Dumper($plan_name) . "\n";

        MATCH: foreach my $def_key (@$def_order){
            my $def_value = $def_dict->{$def_key};

            my @m = ($plan_name =~ m/$def_key/);
            next unless @m;

            # matched vars
            my @mv = eval {
                local $SIG{__WARN__} = sub {};
                ( @m == 1 && $m[0] == 1 ) ? 1 : 0;
            } ? () : @m;

            my $cb = sub {
                local $_ = shift;
                my $j = 0;
                # un-named matches
                for my $w (@mv){
                   $j++;
                   s/\$$j/$w/g;
                }
                # named matches
                for my $k (keys %+){
                   my $v = $+{$k};
                   s/\$\+\{$k\}/$v/g;
                }
                return $_;
            };
            my $vv = clone($def_value);
            dict_exe_cb($vv, $cb);
            dict_update($plan_def, $vv);

            foreach my $pp (qw( sec author_id)) {
                dict_update($plan_def, { $pp => $+{$pp} }) if $+{$pp};
            }
        }

        my $argv = $plan_def->{argv} || '';
        $argv =~ /\s+-t\s+(?<target>\S+)/ && do {
           $plan_def->{target} = $+{target};
        };

        my ($sec, $author_id, $target, $do_children) = @{$plan_def}{qw( sec author_id target do_children )};

        if ($sec) {
            my ($pref) = ($plan_name =~ m/^(.*)$sec/);
            $plan_def->{$_} = $pref for(qw( pref pref_ci ));

            if ($do_children) {
               $plan_def->{children} =  $bld->_sec_children({ sec => $sec });
            }
        }

        if($target){
            my $output = $bld->_trg_output({
                target => $target,
                do_htlatex => $plan_def->{do_htlatex},
            });
            dict_update($plan_def, {
                output => $output,
                output_ex => -f $output,
                output_mtime => -f $output ? stat($output)->mtime : 0,
            });
            print Dumper($plan_def) . "\n";
        }

        if ($author_id) {
            my ($pref) = ($plan_name =~ m/^(.*)$author_id/);
            $plan_def->{pref} = $pref;

            my $cmd = qq{ prj-bld $proj dump_bld -t $target -d 'sii.scts._main_.ii.inner.body' -f json };

            my ($stdout, $stderr) = capture {
               system("$cmd");
               #$bld->run_argv($cmd);
            };
            $stdout ||= '';

            my ($js, @js_data, $js_txt);
            for(split "\n" => $stdout){
                chomp;
                /^begin_json/ && do { $js = 1; next; };
                /^end_json/ && do { undef $js; next; };
                $js && do { push @js_data, $_; next; };
            }
            $js_txt = join("\n",@js_data);
            my $coder = JSON::XS->new->utf8->pretty->allow_nonref;
            $plan_def->{children} = $coder->decode($js_txt) if $do_children;
        }

        if ($do_children) {
            my $children = $plan_def->{children} || [];
            my $pref_ci = $plan_def->{pref_ci} || '';

            my @child_seq = map { $pref_ci . $_ } @$children;
            $bld->run_plans({ plan_seq => \@child_seq });
        }

        print '[BUILDER] Running plan: ' . $plan_name . "\n";
        #print Dumper($plan_def) . "\n";

        my $dry = $plans->{dry} || $plan_def->{dry};
        next if $dry;

        my $rw = $plans->{rw} || $plan_def->{rw};
        my ($output, $output_ex, $output_mtime) = @{$plan_def}{qw( output output_ex output_mtime )};

        my $skip;
        $skip ||= !$rw && $output_ex;

        next if exists $plan_stat->{$plan_name};

        my $status;
        unless ($skip) {
            $bld->run_argv($argv) unless $skip;
            my $plan_ok;
            $plan_ok ||= !$rw && !$output_ex && -f $output;
            $plan_ok ||= $rw && -f $output && ( stat($output)->mtime > $output_mtime );
            $status = $plan_ok ? 'ok' : 'fail';
        }else{
            $status = 'skip';
        }

        dict_update($plan_stat,{
           $plan_name => {
              status => $status,
           }
        });

    }

    return $bld;
}


sub run_plans_after {
    my ($bld, $ref) = @_;
    $ref ||= {};

    my (@ok, @fail, @skip);
    while(my($plan_name, $stat)=each %{$plan_stat}){
        my $status = $stat->{status};
        if ($status eq 'ok') {
           push @ok, $plan_name;
        } elsif ($status eq 'fail') {
           push @fail, $plan_name;
        } elsif ($status eq 'skip') {
           push @skip, $plan_name;
        }
    }

    # no plans executed at all
    return $bld unless @ok || @fail;

    my $delim = '-' x 50;
    my @info;
    push @info,
        $delim, '[BUILDER] plan execution report', $delim,
        @ok ? ( 'SUCCESS:', @ok ) : (),
        @fail ? ( 'FAIL:', @fail ) : (),
        ;

    print $_ . "\n" for(@info);

    return $bld;
}

sub run_argv {
    my ($bld, $argv) = @_;
    $argv ||= '';

    local @ARGV = grep { length $_ } split ' ' => $argv;
    $bld->init({ anew => 1 });
    $bld->{plans} = undef;
    $bld->run;

    return $bld;
}

1;


