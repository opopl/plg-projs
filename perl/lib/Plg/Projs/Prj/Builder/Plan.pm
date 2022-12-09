
package Plg::Projs::Prj::Builder::Plan;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';
use open qw/:std :utf8/;

use Data::Dumper qw(Dumper);

use Capture::Tiny qw(capture);
use Clone qw(clone);
use String::Util qw(trim);

use JSON::XS;
use YAML::XS qw();

use File::Spec::Functions qw(catfile);
use File::stat;
use File::Slurp::Unicode;
use File::Basename qw(basename);

use File::Dat::Utils qw(
   readarr
);

use Base::Arg qw(
   dict_exe_cb
   list_exe_cb

   dict_update
   dict_new

   varexp
   varval

   dump_enc
);

my $plan_stat = {};

sub _plan_def {
    my ($bld, $ref) = @_;
    $ref ||= {};

    my $plan_def = $bld->{plan_def};

    return $plan_def;
}

sub plan_exec {
    my ($bld, $ref) = @_;
    $ref ||= {};

    my $proj = $bld->{proj};

    my ($name, $def, $plans) = @{$ref}{qw(name def plans)};

    my $argv = $def->{argv} || '';

    # fail file
    my $ffile = varval('vars.fail_file' => $plans) || sprintf('%s.plan.fail.i.dat',$proj);

    print '[BUILDER] Running plan: ' . $name . "\n";
    my $dmp = $plans->{dmp} || $def->{dmp};
    print Dumper($def) . "\n" if $dmp;

    my $dry = $plans->{dry} || $def->{dry};
    return $bld if $dry;

    my $rw = $plans->{rw} || $def->{rw};
    my ($output, $output_ex, $output_mtime) = @{$def}{qw( output output_ex output_mtime )};

    my $onfail = varval('exec.onfail' => $plans) || {};

    my $skip;
    $skip ||= !$rw && $output_ex;

    return $bld if exists $plan_stat->{$name};

    my $status;
    unless ($skip) {
        $bld->run_argv($argv) unless $skip;
        my $plan_ok;
        if ($output && defined $output_ex) {
            $plan_ok ||= !$rw && !$output_ex && -f $output;
            $plan_ok ||= $rw && -f $output && ( stat($output)->mtime > $output_mtime );
        }else{
            $plan_ok = 1;
        }
        $status = $plan_ok ? 'success' : 'fail';

        if ($ffile && -f $ffile) {
            my @lines;
            my @flist = read_file($ffile);
            for(@flist){
               chomp; $_ = trim($_);

               if ($plan_ok) {
                   next if /^#/;
                   my $pref = /^$name$/ ? '#' : '';
                   $_ = $pref . $_;
               }
            }
            write_file($ffile,join("\n",@flist) . "\n") if $plan_ok;
        }
    }else{
        $status = 'skip';
    }

    dict_update($plan_stat,{
       $name => {
          status => $status,
       }
    });

    if ($status eq 'fail'){
        #print dump_enc($bld->{err}) =~ s/\\x\{([0-9a-f]{2,})\}/chr hex $1/ger;
        my $err = $bld->{err};
        my ($fpath, $sec) = @{$err}{qw(file sec)};

        my $err_file = 'plan.err.yaml';
        YAML::XS::DumpFile($err_file => $err);

        if (grep { /$^O/ } qw(linux darwin)) {
           system("test -h err.tex && rm err.tex");
           system("ln -s $fpath err.tex");
        }else{
           copy($fpath, 'err.tex');
        }
        my $sd = $bld->_sec_data({
           sec => $sec,
        });
        my $sec_path = $sd->{'@file_path'};
        if ($sec_path && -f $sec_path){
            if (grep { /$^O/ } qw(linux darwin)) {
               system("test -h err.sec.tx && rm err.sec.tx");
               system("ln -s $sec_path err.sec.tx");
            }
        }
        $DB::single = 1;

        warn "[BUILDER.plan.fail] plan fail, see $err_file for details" . "\n";
        exit 1 if $onfail->{die};

    }elsif($status eq 'success'){
        my $output = $def->{output};
        my $obn = basename($output);
        my ($ext) = ( $obn =~ /\.(\w+)$/ );
        if (grep { /$^O/ } qw(linux darwin)) {
          my $ln = catfile($ENV{HOME},qw(Documents),"plan.output.$ext");
          system("test -h $ln && rm $ln");
          system("ln -s $output $ln");
        }

        print "[BUILDER.plan.ok] plan success: $name" . "\n";
    }

    return $bld;
}

sub run_plans {
    my ($bld, $ref) = @_;
    $ref ||= {};

    my $proj = $bld->{proj};

    my $mkr = $bld->{maker};

    my $plans    = $ref->{plans} || $bld->{plans} || {};
    my $plan_seq = clone( $ref->{plan_seq} || $plans->{seq} || [] );

    my $define = clone( $plans->{define} || {} );

    my ($def_dict, $def_order) = $bld->_obj2dict_order($define);

    my $plan_vars = $plans->{vars} || {};
    #list_exe_cb($plan_seq, { cb_list => sub { varexp(shift,$plan_vars) } });
    varexp($plan_seq, $plan_vars);

    my $lim = varval('seq.limit', $plan_vars);

    $DB::single = 1;

    my $j_seq = 0;
    SEQ: while(@$plan_seq) {
        my $plan_name = shift @$plan_seq;
        $plan_name = trim($plan_name) unless ref $plan_name;

        my $plan_def = {};

        if (ref $plan_name eq 'HASH') {
            while(my($k,$v)=each %{$plan_name}){
               $k = trim($k);
               if ($k =~ m/^(\S+)\+\s*$/) {
                   my $plus = $1;
                   if (ref $v eq 'ARRAY') {
                       unshift @$plan_seq, map { $plus . $_ } @$v;
                   }
                   next SEQ;

               }elsif($k eq 'file'){
                   my $file = $v;
                   next unless -f $file;


                   local $_ = $file;
                   /\.i\.dat$/ && do {
                       my @list = readarr($file);
                       unshift @$plan_seq, @list;
                   };
                   $DB::single = 1;
                   next SEQ;
               }

            }
            next SEQ;
        }

        $j_seq++;
        last if $lim && $j_seq == $lim+1;

        #print Dumper($define) . "\n";
        #print Dumper($def_dict) . "\n";
        #print Dumper($def_order) . "\n";
        #print Dumper($plan_name) . "\n";

        # stores info for exact name match
        my $def_eq;

        $DB::single = 1;
        MATCH: foreach my $def_key (@$def_order){
            my $def_value = $def_dict->{$def_key};

            if ($plan_name eq $def_key) {
                $def_eq = $def_value;
                next MATCH;
            }

            my @m = ($plan_name =~ m/$def_key/);
            next unless @m;

            my %named = %+;

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
                for my $k (keys %named){
                   my $v = $named{$k};
                   s/\$\+\{$k\}/$v/g;
                }
                return $_;
            };
            my $vv = clone($def_value);
            dict_exe_cb($vv, { cb => $cb });
            dict_update($plan_def, $vv);

            foreach my $pp (qw( sec author_id)) {
                dict_update($plan_def, { $pp => $+{$pp} }) if $+{$pp};
            }
        }
        dict_update($plan_def, $def_eq) if $def_eq;

        my $argv = $plan_def->{argv} || '';
        unless ($argv) {
            warn '[BUILDER.plan] argv zero, plan = ' . $plan_name . "\n";
            next SEQ;
        }

        print '[BUILDER] Found plan: ' . $plan_name . "\n";

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
                output_ex => -f $output ? 1 : 0,
                output_mtime => -f $output ? stat($output)->mtime : 0,
            });
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

            if (@$children) {
                print '[BUILDER] Found children' . "\n";
                my @child_seq = map { $pref_ci . $_ } @$children;
                $bld->run_plans({ plan_seq => \@child_seq });
            }
        }
        $DB::single = 1;

        $bld->plan_exec({
            name => $plan_name,
            def => $plan_def,
            plans => $plans,
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
        if ($status eq 'success') {
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

    YAML::XS::DumpFile('plan.stat.yaml' => {
        stat => $plan_stat,
        ok   => [@ok],
        skip => [@skip],
        fail => [@fail],
    });

    return $bld;
}

sub run_argv {
    my ($bld, $argv) = @_;
    $argv ||= '';

    local @ARGV = grep { length $_ } split ' ' => $argv;
    return $bld unless @ARGV;

    $bld->init({ anew => 1 });
    $bld->{plans} = undef;
    dict_update($bld, dict_new('run.iffail.exit' => 0));
    $bld->run;

    return $bld;
}

1;


