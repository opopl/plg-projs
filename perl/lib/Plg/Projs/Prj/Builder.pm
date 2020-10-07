

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

    Plg::Projs::Prj::Builder::Insert
    Plg::Projs::Prj::Builder::Defs
    Plg::Projs::Prj::Builder::Trg
    Plg::Projs::Prj::Builder::Gen
    Plg::Projs::Prj::Builder::Sct
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
    my ($self) = @_;

    my $h = {
        trg_list => [qw( usual )],
        om_keys => [qw(
            append
            generate
            join_lines
            load_dat 
            sections
            skip
            tex_exe
        )],
        maps_act => {
            'compile'  => 'build_pwg',
            'join'     => 'insert_pwg',
            'show_trg' => sub { 
                foreach my $trg ($self->_trg_list) {
                    print $trg . "\n";
                }
            },
        },
        act_default    => 'compile',
        target_default => 'usual',
    };

    hash_inject($self, $h);

    return $self;
}

sub init {
    my ($self) = @_;

    $self->Plg::Projs::Prj::init();

    $self
        ->inj_base
        ->prj_load_xml
        ->inj_targets
        ->get_act
        ->get_opt
        ->set_target
        ->trg_load_xml
        ->trg_apply
        ->process_config
        ->init_maker
        ;

    return $self;

}

sub set_target {
    my ($self) = @_;

    $self->{target} = $self->_opt_argv_('target',$self->{target_default});
    return $self;
}

sub process_config {
    my ($self) = @_;

    foreach($self->_config) {
        /^xelatex$/ && do {
            $self->{tex_exe} = 'xelatex';
            next;
        };
    }

    return $self;

}

sub _config {
    my ($self) = @_;

    my @c = @{$self->{config} || []};
    return @c;

}

sub _config_set {
    my ($self, $cfg) = @_;

    grep { /^$cfg$/ } @{$self->{config} || []}; 

}

sub print_help {
    my ($self) = @_;

    my @acts = sort keys %{$self->{maps_act} || {}};
    my $acts_s = join(" ",@acts);

    my $trg_list = $self->{trg_list} || [];
    my $trg_list_s = join(" ",@$trg_list);

    print qq{
        LOCATION:
            $0
        USAGE:
            $Script ACT 
            $Script ACT -t TARGET
            $Script ACT -c CONFIG
            $Script ACT -c CONFIG -t TARGET
        ACTS:
            $acts_s
        TARGETS:
            $trg_list_s
        DEFAULT ACT:
            $self->{act_default}
        DEFAULT TARGET:
            $self->{target_default}
        EXAMPLES:
            perl $Script compile -c xelatex
            perl $Script compile -c xelatex -t usual
            perl $Script show_trg 
    } . "\n";
    exit 1;

    return $self;
}

sub get_act {
    my ($self) = @_;

    $self->print_help unless @ARGV;

    my $act = shift @ARGV || 'compile';
    $self->{act} = $act;

    return $self;
}
      
sub get_opt {
    my ($self) = @_;
    
    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));
    
    my %opt;
    my @optstr = ( 
        "config|c=s",
        "target|t=s",
    );

    GetOptions(\%opt,@optstr);
    $self->{opt} = \%opt;
    
    $self->{config} = [ 
        map { s/'//g; s/'$//g; $_ }
        split(',' => ($opt{config} || '')) 
    ];


    return $self;   
}

sub run_maker {
    my ($self) = @_;

    my $m = $self->{maker};

    local @ARGV = ();
    $m->run;

    return $self;
}


sub run {
    my ($self) = @_;

    $self->run_maker;

    return $self;
}

sub init_maker {
    my ($self) = @_;

    my $act = $self->{act};
    my $cmd = $self->{maps_act}->{$act} || '';

    my $target = $self->{target};
    my $proj   = $self->{proj};

    my $pdf_name = join(".", $proj, $target);

    local @ARGV = ();
    #print Dumper($self->{opts_maker}) . "\n";
    #exit;

    if (ref $cmd eq 'CODE') {
        $cmd->();
        exit 0;
    }

    my $om = $self->_trg_opts_maker();
    #my $y = XMLout({ opts_maker => $om }, RootName => 'bld' );
    #print $y . "\n";
    #exit;
	#print Dumper($self->{tex_exe}) . "\n";
	#exit 1;

    my $x = Plg::Projs::Build::Maker->new(
        pdf_name     => $pdf_name,
        proj         => $self->{proj},
        root         => $self->{root},
        root_id      => $self->{root_id},
        cmd          => $cmd,
        %$om,
        tex_exe      => $self->{tex_exe},
		bld          => $self,
    );

    $self->{maker} = $x;

    return $self;
}

1;
 

