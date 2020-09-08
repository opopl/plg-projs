

package Plg::Projs::Prj::Builder;

use strict;
use warnings;

use base qw(
    Plg::Projs::Prj
);

use FindBin qw($Bin $Script);
use Data::Dumper qw(Dumper);

use File::Spec::Functions qw(catfile);
use Getopt::Long qw(GetOptions);

use Base::Arg qw(
	hash_update
);

use Plg::Projs::Build::PdfLatex;

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
    };

	hash_update($self, $h, { keep_already_defined => 1 });

    $self
		->get_act
		->get_opt
		->init_maker
		;


    return $self;
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
                $Script compile -c 'xelatex'
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
    );

    GetOptions(\%opt,@optstr);
    
    $self->{config} = split(',' => ($opt{config} || ''));

    return $self;   
}


sub _insert_titletoc {
    my $self = shift;

    my @d;
    push @d,
            {
###ttt_section
             scts    => [qw( section )],
             lines => [
                 ' ',
                 '\startcontents[subsections]',
    '\printcontents[subsections]{l}{2}{\addtocontents{ptc}{\setcounter{tocdepth}{3}}}',

             ],
             lines_stop => [
                 '\stopcontents[subsections]',
            ]
        },
        {
             scts    => [qw( chapter )],
             lines => [
                 ' ',
                 '\startcontents[sections]',
    '\printcontents[sections]{l}{1}{\addtocontents{ptc}{\setcounter{tocdepth}{1}}}',
                 ' ',
             ],
             lines_stop => [
                 '\stopcontents[sections]',
            ]
        },
        ;
    return [@d];
}

sub run_maker {
    my ($self) = @_;

    local @ARGV = ();
    $self->{maker}->run;

    return $self;
}


sub run {
    my ($self) = @_;

    $self->run_maker;

    return $self;
}

sub init_maker {
    my ($self) = @_;

    my @secs_include;
    #push @secs_include,
        #'13_07_2020',
        #'14_07_2020',
        #'15_07_2020',
        ;


    my $act = $self->{act};
    my $cmd = $self->{maps_act}->{$act} || '';

    local @ARGV = ();
    my $x = Plg::Projs::Build::PdfLatex->new(
        skip_get_opt => 1,
		tex_exe      => $self->{tex_exe},
        proj         => $self->{proj},
        root         => $self->{root},
        root_id      => $self->{root_id},
        cmd          => $cmd,
        join_lines   => {
            include_below => [qw(section)]
        },
        sections => {
            include => \@secs_include,
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
    );

    $self->{maker} = $x;

    return $self;
}

1;
 

