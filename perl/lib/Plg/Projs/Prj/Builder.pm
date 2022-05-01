

package Plg::Projs::Prj::Builder;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

use File::Slurp::Unicode;

use XML::Hash::LX;
use XML::Simple qw( XMLout XMLin );
use Deep::Hash::Utils qw(reach);

use Scalar::Util qw(blessed reftype);

use YAML qw( LoadFile Load Dump DumpFile );

use Base::String qw(
    str_split
    str_split_sn
);

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
    dict_new
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
            %print
        },
        act_default    => 'compile',
        target_default => 'usual',
    };

    hash_inject($bld, $h);

    return $bld;
}

sub init {
    my ($bld) = @_;

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
        ->trg_apply                             # apply $target data into $bld instance
        ->trg_adjust
        ->load_yaml
        ->load_decs
        ->load_patch
        ->process_ii_updown               
        ->process_config
        ->act_exe
        ->init_maker
        ;

    #my $data = LoadFile($file);
    my $s = Dump($bld->{opts_maker});

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
        exit 0;
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
    );

    GetOptions(\%opt,@optstr);
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

sub run {
    my ($bld) = @_;

    $bld->run_maker;

    return $bld;
}

sub init_maker {
    my ($bld) = @_;

    my $act     = $bld->{act};
    my $act_cmd = $bld->{maps_act}->{$act} || '';

    my $target = $bld->{target};
    my $proj   = $bld->{proj};

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
        cmd          => $act_cmd,
        %$om,
        tex_exe      => $bld->{tex_exe},
        bld          => $bld,
    );

    $bld->{maker} = $mkr;


    return $bld;
}

1;
 

