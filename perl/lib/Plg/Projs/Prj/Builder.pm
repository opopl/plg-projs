

package Plg::Projs::Prj::Builder;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

use Capture::Tiny qw(capture);
use File::stat;

use Digest::MD5 qw(md5_hex);

use File::Slurp::Unicode;

use XML::Hash::LX;
use XML::Simple qw( XMLout XMLin );
use Deep::Hash::Utils qw(reach);

use Scalar::Util qw(blessed reftype);
use Clone qw(clone);
use DateTime;

use YAML qw( LoadFile Load Dump DumpFile );

use Base::DB qw(
    dbi_connect
    dbh_insert_hash
    dbh_insert_update_hash
);

use Base::String qw(
    str_split
    str_split_sn
);
use String::Util qw(trim);

use Plg::Projs::GetImg;

use base qw(
    Plg::Projs::Prj
    Plg::Projs::Doc

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
    Plg::Projs::Prj::Builder::Plan

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

    varval
    varexp
);

use Plg::Projs::Build::Maker;

sub init_db_bld {
    my ($bld) = @_;

    my $dbh_bld = dbi_connect({
        dbfile => catfile($bld->{root},qw(bld.db))
    });

    $bld->{dbh_bld} = $dbh_bld;
    $bld->init_db_tables({
       dbh => $dbh_bld,
       table_order => [qw( builds )],
       prefix => 'bld.create_table_',
    });

    return $bld;
}

sub init_db_doc {
    my ($bld) = @_;

    my $dbh_doc = dbi_connect({
        dbfile => catfile($bld->{doc_root},qw(doc.db))
    });

    $bld->{dbh_doc} = $dbh_doc;
    $bld->init_db_tables({
       dbh => $dbh_doc,
       table_order => [qw( docs )],
       prefix => 'doc.create_table_',
    });

    return $bld;
}

sub inj_base {
    my ($bld) = @_;

    my %print = map { my $a = $_; ( $a => $a ) } qw(
        print_ii_include
        print_ii_base
        print_ii_exclude
        print_ii_body
        print_ii_body_raw
    );

    my $h = {
        ok => 1,

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
    $bld->Plg::Projs::Doc::init();

    $bld->{build} = {
        cmda => [$0, @ARGV],
    };

    return $bld if $bld->{bld_skip_init};

    $bld
        ->init_db_bld
        ->init_db_doc
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
        ->trg_adjust_conf
        ->load_decs
        ->load_patch
        ->process_ii_updown
        ->process_config
        ->expand_env
        ->expand_vars
        ->init_imgman
        ->init_maker
        ->act_exe
        ;

    $DB::single = 1;

    #my $data = LoadFile($file);
    my $s = Dump($bld->{opts_maker});

    my @c = $bld->_config;
    my $cnf = @c ? join("," => @c) : '';
    my ($act, $target) = @{$bld}{qw( act target )};
    print qq{[BUILDER] act = $act, target = $target, config = $cnf } . "\n";

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

sub expand_vars {
  my ($bld) = @_;

  my $vars = $bld->{vars};
  my $cb = sub {
      local $_ = shift;
      return unless defined $_;
      s/\@var\{(\w+)\}/$bld->_bld_var($1)/ge;
      return $_;
  };
  foreach my $x (qw(opts_maker sii)) {
    #dict_exe_cb($bld->{$x},{ cb => $cb });
    varexp($bld->{$x}, $bld->{vars}, { pref => '\@' });
  }
  # x $bld->_vals_('sii.scts')
  # x $bld->_vals_('sii@scts@preamble.fancyhdr','@')
  # x $bld->_vals_('sii@scts@_main_@ii@inner@start','@')

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

        /^capture$/ && do {
            dict_update($bld, dict_new('run_tex.shell','capture'));
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

    $bld->{ok} &&= $bld->{maker}->{ok};

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

sub _pln_build_status {
    my ($bld) = @_;
}

sub _pln {
    my ($bld) = @_;

    my ($act, $do_htlatex, $target) = @{$bld}{qw( act do_htlatex target )};

    my $trg = $target;
    $target =~ /^_(buf|auth)\.(.*)$/ && do {
       $trg = join("." => $1, $2);
    };
    my $pln = join '.' => ($act, $do_htlatex ? 'htx' : 'pdf', $trg );

    $bld->{target_ext} ||= $do_htlatex ? 'html' : 'pdf';

    return $pln;
}

sub build_update_start {
    my ($bld) = @_;

    my $pln = $bld->_pln;
    my $start = time();
    my $md5 = md5_hex($pln);
    my $buuid = join '@' => $start, $md5;

    dict_update($bld->{build}, {
       start => $start,
       buuid => $buuid,
       status => 'running',
       plan => $pln,
    });

    $bld->build_update_db({
        status => 'running',
    });

    return $bld;
}

sub build_update_db {
    my ($bld, $data) = @_;
    $data ||= {};

    my $pln = $bld->_vals_('build.plan');
    my $buuid = $bld->_vals_('build.buuid');

    my $ref = {
        dbh => $bld->{dbh_bld},
        t => 'builds',
        #i => q{INSERT OR IGNORE},
        h => {
            plan => $pln,
            cmd => join(" " => @{$bld->_vals_('build.cmda') || []}),
            status => $bld->{ok} ? 'success' : 'fail',
            start => $bld->_vals_('build.start'),
            sec => $bld->_vals_('build.sec'),
            duration => 0,

            ( map { $_ => $bld->{$_} } qw( proj target target_ext ) ),
            %$data,
            buuid => $buuid,
        },
        on_list => [qw( buuid )]
    };
    dbh_insert_update_hash($ref);

    return $bld;
}

sub build_update_end {
    my ($bld) = @_;

    my $start = $bld->_vals_('build.start');
    my $end = time();

    my $pln = $bld->_vals_('build.plan');

    my $duration = $end - $start;

    my $err = $bld->{ok} ? '' : $bld->_vals_('build.errors.msg');
    $bld->build_update_db({
        status => $bld->{ok} ? 'success' : 'fail',
        duration => $duration,
        $err ? ( err => $err ) : (),
    });

    return $bld;
}

sub ok_after {
    my ($bld) = @_;

    #print Dumper({ map { $_ => $bld->{$_} } qw(sec build) }) . "\n";
    my $pln = $bld->_vals_('build.plan');

    if($bld->{ok}){
        print '[BUILDER.ok] run success' . "\n";
        exit 0 if $bld->_vals_('run.ifok.exit');
        return $bld;
    }

    my $ff = varval('plans.vars.fail_file' => $bld);
    my (%fail, @fails_read, @fails_write);

    if ($ff) {
        @fails_read = -f $ff ? read_file $ff : ();
        my @lines = @fails_read;

        my $sp = join("",qw( + + ));
        while(@lines){
            local $_ = shift @lines;
            chomp;

            my $failed = /^\s*#/ ? 1 : 0;

            s/^[#]*//g; $_ = trim($_);
            next unless length $_;
            next if /\+\+/ || !/^\w/;

            $fail{$_} = 1 if $failed;
        }
        my $af = 'af';

        $fail{$pln} ||= 1;
        my $done;
        for(@fails_read){
            chomp;
            $_ = trim($_);

            /^[#]+(.*)$/ && do {
                my $p = $1;
                do { $done = 1; $_ = $p } if $p eq $pln;
            };
            /^([^#].*)$/ && do {
                my $p = $1;
                $done = 1 if $p eq $pln;
            };

            push @fails_write, $_;
        }
        push @fails_write, $pln unless $done;

        write_file($ff,join("\n",@fails_write) . "\n");
    }

    warn '[BUILDER.fail] run fail' . "\n";
    exit 1 if $bld->_vals_('run.iffail.exit');

    return $bld;
}

sub run {
    my ($bld) = @_;

    return $bld if $bld->{skip_run};

    my $act     = $bld->{act};

    if($act eq 'plan'){
        $bld
            ->run_plans
            ->run_plans_after;
    }else{
        $bld
            ->build_update_start
            ->run_maker
            ->build_update_end
            ->ok_after;
    }

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


