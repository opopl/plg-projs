

package Plg::Projs::Prj::Builder;

use strict;
use warnings;

use base qw(
    Base::Obj

    Plg::Projs::Prj
    Plg::Projs::Prj::Builder::Insert
    Plg::Projs::Prj::Builder::Defs
    Plg::Projs::Prj::Builder::Trg
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
        tex_exe => 'pdflatex',
        maps_act => {
            'compile'  => 'build_pwg',
            'join'     => 'insert_pwg',
            'show_trg' => sub { 
                foreach my $trg ($self->trg_list) {
                    print $trg . "\n";
                }
            },
        },
        act_default => 'compile',
        target_default => 'usual',
        targets => [qw( usual )],
        insert => {
            titletoc   => 1,
            hyperlinks => 1,
        },
    };

    hash_inject($self, $h);

    return $self;
}

sub inj_opts_maker {
    my ($self) = @_;

    my $o = {
        skip_get_opt => 1,
        join_lines   => {
            include_below => [qw(section)]
        },
        # _ii_include
        # _ii_exclude
        load_dat => {
            ii_include => 1,
            ii_exclude => 1,
        },
        sections => { 
            include => $self->_secs_include,
            line_sub => sub {
                my ($line,$r_sec) = @_;
    
                my $sec = $r_sec->{sec};
    
                return $line;
            },
            ins_order => [qw( hyperlinks titletoc )],
            insert => {
                titletoc   => $self->_insert_titletoc,
                hyperlinks => $self->_insert_hyperlinks,
            },
            generate => {
            },
            append => {
                each => sub { },
                only => {
                    defs => sub {
                        [ $self->_def_sechyperlinks ];
                    },
                },
            },
        }
    };
    my $h = { opts_maker => $o };

    hash_inject($self, $h);

    return $self;
}

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self
        ->inj_base
        ->inj_opts_maker
        ->get_act
        ->get_opt
        ->process_config
        ->init_maker
        ;


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

    my $targets = $self->{targets} || [];
    my $targets_s = join(" ",@$targets);

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
            $targets_s
        DEFAULT ACT:
            $self->{act_default}
        DEFAULT TARGET:
            $self->{target_default}
        EXAMPLES:
            perl $Script compile -c 'xelatex'
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

sub _secs_include {
    my ($self) = @_;

    my @secs;

    return [@secs];
}

sub init_maker {
    my ($self) = @_;

    my $act = $self->{act};
    my $cmd = $self->{maps_act}->{$act} || '';

    local @ARGV = ();

    if (ref $cmd eq 'CODE') {
        $cmd->();
        exit 0;
    }

    my $x = Plg::Projs::Build::Maker->new(
        tex_exe      => $self->{tex_exe},
        proj         => $self->{proj},
        root         => $self->{root},
        root_id      => $self->{root_id},
        cmd          => $cmd,
        %{ $self->{opts_maker} || {} },
    );

    $self->{maker} = $x;

    return $self;
}

1;
 

