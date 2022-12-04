

package Plg::Projs::Prj::Builder;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

use Capture::Tiny qw(capture);


use File::Slurp::Unicode;

use XML::Hash::LX;
use XML::Simple qw( XMLout XMLin );
use Deep::Hash::Utils qw(reach);

use Scalar::Util qw(blessed reftype);
use Clone qw(clone);

use YAML qw( LoadFile Load Dump DumpFile );

use Base::String qw(
    str_split
    str_split_sn
);

use Plg::Projs::GetImg;

use base qw(
    Plg::Projs::Prj

    Base::Obj
    Base::Opt

    Plg::Projs::Prj::Builder::Act
    Plg::Projs::Prj::Builder::Defs
    Plg::Projs::Prj::Builder::Dmp
    Plg::Projs::Prj::Builder::Gen
    Plg::Projs::Prj::Builder::Insert
    Plg::Projs::Prj::Builder::Trg
    Plg::Projs::Prj::Builder::Txt
    Plg::Projs::Prj::Builder::Var

    Plg::Projs::Prj::Builder::Sct
    Plg::Projs::Prj::Builder::Sct::Index
);

use FindBin qw($Bin $Script);
use Data::Dumper qw(Dumper);

use File::Spec::Functions qw(catfile);
use Getopt::Long qw(GetOptions);

use Base::String qw(
    str_split_sn
);

use Base::Arg qw(
    hash_inject

    dict_update
    dict_exe_cb
    dict_new

    dict_expand_env
);

use Plg::Projs::Build::Maker;

sub inj_base {
    my ($bld) = @_;

    my %print = map { my $a = $_; ( $a => $a ) } qw(
        print_ii_include
        print_ii_base
        print_ii_exclude
        print_ii_tree
    );

    my $h = {
        trg_list => [qw( usual )],
        maps_act => {
            # Plg::Projs::Build::Maker::Jnd cmd_jnd_build
            'compile'          => 'jnd_build',
            # Plg::Projs::Build::Maker::Jnd cmd_jnd_compose
            'join'             => 'jnd_compose',
            'relax'            => 'relax',
            'show_trg'         => sub { $bld->act_show_trg; },
            'show_acts'        => sub { $bld->act_show_acts; },
            'dump_bld'         => sub { $bld->act_dump_bld; },

            'db_sync'          => sub { $bld->act_db_sync; },
            'db_push'          => sub { $bld->act_db_push; },
            'db_pull'          => sub { $bld->act_db_pull; },
            %print,
            %{$bld->{custom}->{maps_act} || {}}
        },
        act_default    => 'compile',
        target_default => 'usual',
    };

    hash_inject($bld, $h);

    return $bld;
}

sub init {
    my ($bld, $ref) = @_;
    $ref ||= {};

    if ($ref->{anew}) {
       delete $bld->{$_} for keys %$bld;
    }

    $bld->Plg::Projs::Prj::init();

    return $bld if $bld->{bld_skip_init};

    $bld
        ->inj_base
        ->prj_load_yml # process PROJ.yml file, set trg_list
        ->inj_targets
        ->get_act
        ->get_opt
        ->set_target                            # set $bld->{target} from --target switch
        ->trg_load_yml({ 'target' => 'core' })  # load into targets/core
        ->trg_load_yml                          # load into targets/$target
        ->trg_apply('core')                     # apply 'core' target data into $bld instance
        ->cnf_apply                             # $bld->{cnf} => $bld except 'targets' section
        ->trg_apply                             # apply $target data into $bld instance
        ->trg_adjust
        ->load_yaml
        ->load_decs
        ->load_patch
        ->process_ii_updown
        ->process_config
        ->expand_env
        ->init_imgman
        ->init_maker
        ->act_exe
        ;

    $DB::single = 1;

    #my $data = LoadFile($file);
    my $s = Dump($bld->{opts_maker});

    return $bld;
}

sub init_imgman {
  my ($bld) = @_;

  my $img_root = $bld->_bld_var('img_root');
  my ($proj, $root, $rootid) = @{$bld}{qw( proj root root_id )};

  my $imgman = Plg::Projs::GetImg->new(
     skip_get_opt => 1,
     img_root => $img_root,
     proj   => $proj,
     root   => $root,
     rootid => $rootid,
  );

  $bld->{imgman} = $imgman;


  return $bld;
}


sub expand_env {
    my ($bld) = @_;

    dict_expand_env($bld->{vars});

    return $bld;
}

sub load_decs {
    my ($bld) = @_;

    my $decs = $bld->{decs} || [];
    if (ref $decs eq 'HASH') {
        $decs = $bld->{decs} = [ map { $decs->{$_} ? $_ : () } keys %$decs ];
    }

    foreach(@$decs) {
        /^om_iall$/ && do {
            dict_update($bld, dict_new('patch.opts_maker.ii_include_all',1));
            next;
        };
    }

    return $bld;
}

sub load_patch {
    my ($bld) = @_;

    my $patch = $bld->{patch} || {};
    while(my($k,$v)=each %$patch){
        my $d = dict_new($k, $v);
        dict_update($bld, $d);

        #my @path = split '\.' => $k;
        #my $dd = $bld->_val_(@path);
    }

    return $bld;
}

sub load_yaml {
    my ($bld) = @_;

    my @yfiles = @{$bld->{opt}->{yfile} || []};
    push @yfiles, 'bld.yml';

    my %done;
    foreach my $yfile (@yfiles) {
        next unless -f $yfile;
        next if $done{$yfile};

        my $d = LoadFile($yfile);
        dict_update($bld, $d);
        $done{$yfile} = 1;
    }

    return $bld;
}

sub quit {
    my ($bld) = @_;
    exit 1;
    return $bld;

}

sub act_exe {
    my ($bld) = @_;

    my $act     = $bld->{act};
    my $act_cmd = $bld->{maps_act}->{$act} || '';

    if (ref $act_cmd eq 'CODE') {
        $act_cmd->();
        $bld->{skip_run} = 1;
    }
    return $bld;
}

sub set_target {
    my ($bld) = @_;

    local $_ = $bld->{target} = $bld->_opt_argv_('target',$bld->{target_default});
    return $bld;
}

sub process_config {
    my ($bld) = @_;

    foreach($bld->_config) {
        /^xelatex$/ && do {
            $bld->{tex_exe} = 'xelatex';
            next;
        };

        # compile in box environment with all
        #   images copied locally
        /^box$/ && do {
            $bld->{box} = 1;
            next;
        };

        # compile with htlatex
        /^htx$/ && do {
            $bld->{do_htlatex} = 1;
            next;
        };
    }

    return $bld;

}

sub _config {
    my ($bld) = @_;

    my @c = @{$bld->{config} || []};
    return @c;

}

sub _config_set {
    my ($bld, $cfg) = @_;

    grep { /^$cfg$/ } @{$bld->{config} || []};

}

sub print_help {
    my ($bld) = @_;

    my @acts   = $bld->_acts;
    my $acts_s = join("\n",map { (" "x13) . $_} sort @acts);

    my $trg_list   = $bld->{trg_list} || [];
    my $trg_list_s = join(" ",@$trg_list);

    print qq{
        LOCATION:
            $0
        OPTIONS:
             -t --target TARGET

             -d --data DATA #TODO
             -c --config CONFIG e.g. 'xelatex' (comma-separated list)
             -y --yfile YAML FILE

        USAGE:
             perl $Script ACT
             perl $Script ACT -t TARGET
             perl $Script ACT -c CONFIG
             perl $Script ACT -c CONFIG -t TARGET
             perl $Script ACT -c CONFIG -t TARGET -d DATA
        ACTS:
$acts_s
        TARGETS:
            $trg_list_s
        DEFAULT ACT:
            $bld->{act_default}
        DEFAULT TARGET:
            $bld->{target_default}
        EXAMPLES:
            perl $Script compile -c xelatex
            perl $Script compile -c xelatex -t usual
            perl $Script compile -c xelatex -t usual -y a.yaml -y b.yaml
            perl $Script show_trg
            perl $Script show_acts
            perl $Script dump_bld -d 'opts_maker sections'
            perl $Script join
            perl $Script print_ii_include
            perl $Script -i a.zc
        DEBUG:
            perl -d $Script join
    } . "\n";
    exit 1;

    return $bld;
}

sub get_act {
    my ($bld) = @_;

    $bld->print_help unless @ARGV;

    my $act = shift @ARGV || 'compile';
    $bld->{act} = $act;

    return $bld;
}

sub get_opt {
    my ($bld) = @_;

    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));

    my %opt;
    my @optstr = (
        "config|c=s",
        "target|t=s",
        "data|d=s",
        "ii_updown=s",
        "yfile|y=s@",

        # output format e.g. json, yaml for dump_bld command
        'format|f=s',
    );

    GetOptions(\%opt, @optstr);
    $bld->{opt} = \%opt;

    $bld->{config} = [
        map { s/'//g; s/'$//g; $_ }
        split(',' => ($opt{config} || ''))
    ];

    return $bld;
}

sub run_maker {
    my ($bld) = @_;

    my $mkr = $bld->{maker};

    local @ARGV = ();
    $mkr->run;

    return $bld;
}

sub process_ii_updown {
    my ($bld) = @_;

    foreach my $x (qw(ii_updown)) {
        my $v = $bld->{opt}->{$x};
        next unless $v;

        $bld->_bld_var_set({ $x => $v });

        for($x){
            /^ii_updown$/ && do {
                my $sec_updown = $v;
                my $t = sprintf('buf.%s',$sec_updown);
                $bld->trg_list_add($t);
                last;
            };
            last;
        }
    }

    return $bld;
}

sub _obj2dict_order {
    my ($bld, $obj) = @_;

    my (%dict, @order);

    if (ref $obj eq 'HASH') {
        push @order, keys %$obj;
        %dict = %$obj;
    }elsif(ref $obj eq 'ARRAY'){
        foreach my $x (@$obj) {
            my ($dict_key) = keys %$x;
            my $dict_value = $x->{$dict_key};

            push @order, $dict_key;
            $dict{$dict_key} = $dict_value;
        }
    }

    return (\%dict, \@order);
}

sub run_plans {
    my ($bld, $ref) = @_;
    $ref ||= {};

    my $proj = $bld->{proj};

    my $mkr = $bld->{maker};

    my $plans    = $ref->{plans} || $bld->{plans} || {};
    my $plan_seq = $ref->{plan_seq} || $plans->{seq} || [];

    my $define = clone( $plans->{define} || {} );

    my ($def_dict, $def_order) = $bld->_obj2dict_order($define);
    $DB::single = 1;

    foreach my $plan_name (@$plan_seq) {
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
            my $output = catfile($mkr->{out_dir_html},$target,'jnd_ht.html');
            dict_update($plan_def, {
                output => $output,
                output_ex => -f $output,
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

            my @child_seq = map { $pref_ci . $_ } @$children;
            $bld->run_plans({ plan_seq => \@child_seq });
        }

        print '[BUILDER] Running plan: ' . $plan_name . "\n";
        #print Dumper($plan_def) . "\n";

        my $dry = $plans->{dry} || $plan_def->{dry};
        next if $dry;

        my $rw = $plans->{rw} || $plan_def->{rw};
        my $output_ex = $plan_def->{output_ex};

        next if !$rw && $output_ex;

        $bld->run_argv($argv);
    }

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


sub run {
    my ($bld) = @_;

    return $bld if $bld->{skip_run};

    my $plans = $bld->{plans} || {};
    my $plan_seq = $plans->{seq} || [];

    if(!@$plan_seq) {
        $bld->run_maker;
        return $bld;
    }

    $bld->run_plans;

    return $bld;
}

sub init_maker {
    my ($bld) = @_;

    my $act     = $bld->{act};
    my $act_cmd = $bld->{maps_act}->{$act} || '';

    my ($target, $proj) = @{$bld}{qw( target proj )};

    my $pdf_name = join(".", $proj, $target);

    local @ARGV = ();

    my $om = $bld->_val_('opts_maker');
    #my $y = XMLout({ opts_maker => $om }, RootName => 'bld' );
    #print $y . "\n";
    #exit;
    #print Dumper($bld->{tex_exe}) . "\n";
    #exit 1;
    #

    my $mkr = Plg::Projs::Build::Maker->new(
        pdf_name     => $pdf_name,
        proj         => $bld->{proj},
        root         => $bld->{root},
        root_id      => $bld->{root_id},
        cmd          => !ref $act_cmd ? $act_cmd : 'compile',
        %$om,
        tex_exe      => $bld->{tex_exe},
        bld          => $bld,

        map { $_ => $bld->{$_} } qw(
            box
            do_htlatex
            tex4ht
        )
    );

    $bld->{maker} = $mkr;

    return $bld;
}

1;


