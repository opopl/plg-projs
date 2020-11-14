

package Plg::Projs::Prj::Builder;

use utf8;
use strict;
use warnings;

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
);

use FindBin qw($Bin $Script);
use Data::Dumper qw(Dumper);

use File::Spec::Functions qw(catfile);
use Getopt::Long qw(GetOptions);

use Base::Arg qw(
    hash_update
    hash_inject
);

use Plg::Projs::Build::Maker;

sub inj_base {
    my ($bld) = @_;

    my $h = {
        trg_list => [qw( usual )],
        maps_act => {
            'compile_pwg' => 'build_pwg',
            'compile'     => 'jnd_build',
            'join'        => 'jnd_compose',
            'show_trg'  => sub { $bld->act_show_trg; },
            'show_acts' => sub { $bld->act_show_acts; },
            'dump_bld'  => sub { $bld->act_dump_bld; },
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

    $bld
        ->inj_base
        ->prj_load_xml
        ->inj_targets
        ->get_act
        ->get_opt
        ->set_target
        ->trg_load_xml({ 'target' => 'core' })
        ->trg_load_xml
        ->trg_apply('core')
        ->trg_apply
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

    $bld->{target} = $bld->_opt_argv_('target',$bld->{target_default});
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
    my $acts_s = join(" ",@acts);

    my $trg_list   = $bld->{trg_list} || [];
    my $trg_list_s = join(" ",@$trg_list);

    print qq{
        LOCATION:
            $0
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

    my $m = $bld->{maker};

    local @ARGV = ();
    $m->run;

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
 

