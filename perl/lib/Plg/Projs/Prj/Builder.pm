

package Plg::Projs::Prj::Builder;

use strict;
use warnings;

use base qw(
    Base::Obj

    Plg::Projs::Prj
    Plg::Projs::Prj::Builder::Insert
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

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    my $h = {
        tex_exe => 'pdflatex',
        maps_act => {
            'compile' => 'build_pwg',
            'join'    => 'insert_pwg',
        },
        act_default => 'compile',
        insert => {
            titletoc   => 1,
            hyperlinks => 1,
        },
    };
    hash_inject($self, $h);

    $h = {
        opts_maker => {
            # _ii_include
            # _ii_exclude
            load_dat => {
                ii_include => 1,
                ii_exclude => 1,
            },
            # generate files
            generate => {
            },
    
            # append to files
            append => {
                defs => sub {},
            },

            sections => { 
                include => $self->_secs_include,
                line_sub => sub {
                    my ($line,$r_sec) = @_;
        
                    my $sec = $r_sec->{sec};
        
                    return $line;
                },
                insert => {
                    titletoc   => $self->_insert_titletoc,
                    hyperlinks => $self->_insert_hyperlinks,
                },
            }
        },
    };

    hash_inject($self, $h);

    $self
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

sub get_act {
    my ($self) = @_;

    my @acts = sort keys %{$self->{maps_act} || {}};
    my $acts_s = join(" ",@acts);

    unless (@ARGV) {
        print qq{
            LOCATION:
                $0
            USAGE:
                $Script ACT -c CONFIG
            ACTS:
                $acts_s
            DEFAULT ACT:
                $self->{act_default}
            EXAMPLES:
                perl $Script compile -c 'xelatex'
        } . "\n";
        exit 1;
    }

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

    my $x = Plg::Projs::Build::Maker->new(
        skip_get_opt => 1,
        tex_exe      => $self->{tex_exe},
        proj         => $self->{proj},
        root         => $self->{root},
        root_id      => $self->{root_id},
        cmd          => $cmd,
        join_lines   => {
            include_below => [qw(section)]
        },
        %{ $self->{opts_maker} || {} },
    );

    $self->{maker} = $x;

    return $self;
}

1;
 

