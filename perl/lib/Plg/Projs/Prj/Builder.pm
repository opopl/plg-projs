

package Plg::Projs::Prj::Builder;

use utf8;
use strict;
use warnings;

use File::Slurp::Unicode;

use XML::Hash::LX;
use XML::Simple qw( XMLout XMLin );
use Deep::Hash::Utils qw(reach);

use base qw(
    Plg::Projs::Prj

    Base::Obj
    Base::Opt

    Plg::Projs::Prj::Builder::Act
    Plg::Projs::Prj::Builder::Defs
    Plg::Projs::Prj::Builder::Dmp
    Plg::Projs::Prj::Builder::Gen
    Plg::Projs::Prj::Builder::Insert
    Plg::Projs::Prj::Builder::Sct
    Plg::Projs::Prj::Builder::Trg
    Plg::Projs::Prj::Builder::Txt
    Plg::Projs::Prj::Builder::Var
);

use FindBin qw($Bin $Script);
use Data::Dumper qw(Dumper);

use File::Spec::Functions qw(catfile);
use Getopt::Long qw(GetOptions);

use Base::String qw(
    str_split_sn
);

use Base::Arg qw(
    hash_update
    hash_inject
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

    my %old = (
        # Plg::Projs::Build::Maker::Pwg cmd_build_pwg
       'compile_pwg'      => 'build_pwg',
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
            %print,
            %old
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
        ->prj_load_xml          # process PROJ.xml file, set trg_list
        ->inj_targets
        ->get_act
        ->get_opt
        ->set_target                            # set $bld->{target} from --target switch
        ->trg_load_xml({ 'target' => 'core' })  # load into targets/core 
        ->trg_load_xml                          # load into targets/$target
        ->trg_apply('core')                     # apply 'core' target data into $bld instance
        ->trg_apply                             # apply $target data into $bld instance
        ->read_in_file                  # process -i --in_file switch
        ->process_ii_updown               
        ->process_config
        ->act_exe
        ->init_maker
        ;

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
    if (/^_buf\.(\S+)$/) {
        my $sec = $1;

        $bld->{opt}->{ii_updown} = $sec;
    }
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
             -c --config CONFIG e.g. 'xelatex'
             -i --in_file INFILE
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
        "in_file|i=s",
        "ii_updown=s",
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

        if (ref $bld->{vars} eq 'ARRAY') {
            push @{$bld->{vars}}, { 
                name  => $x,
                value => $v,
            };
        }

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

sub read_in_file {
    my ($bld) = @_;

    my $in_file = $bld->_opt_argv_('in_file','');
    return $bld unless ($in_file && -e $in_file);

    my ($ext) = ( $in_file =~ m/\.(\w+)$/ );
    for($ext){
        /^zc$/ && do {
            my @lines = read_file $in_file;

            my ($var_name, $var_type, %vars);
            while(@lines){
                local $_ = shift @lines;
                chomp;

                next if /^[\s\t]+#/;

                /^list\s+(\w+)$/ && do {
                    $var_type = 'list';
                    $var_name = $1;
                    next;
                };

                /^[\t]+(.*)$/ && do {
                    my $val = $1;
                    if ($var_type eq 'list') {
                        $vars{$var_name} ||= [];
                        push @{$vars{$var_name}}, str_split_sn($val);
                    }
                };
            }
            $bld->{ctl} ||= {}; 
            $bld->{ctl}->{vars} = \%vars; 
            while(my($k,$v) = each %vars){
                if (ref $bld->{vars} eq 'ARRAY') {
                    push @{$bld->{vars}}, { 
                        name  => $k,
                        value => $v,
                    };
                }
            }
        };
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
 

