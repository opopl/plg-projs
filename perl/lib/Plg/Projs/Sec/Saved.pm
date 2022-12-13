
package Plg::Projs::Sec::Saved;

use utf8;
use strict;
use warnings;

binmode STDOUT,':encoding(utf8)';

use Data::Dumper qw(Dumper);
use FindBin qw($Bin $Script);
use YAML qw(LoadFile);
use Getopt::Long qw(GetOptions);

use Plg::Projs::GetImg;

use Base::Enc qw( unc_decode );
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);
use File::Copy qw(copy);
use File::Slurp::Unicode;
use File::Basename qw(basename dirname);
use Cwd qw(getcwd);

use XML::LibXML;
use XML::LibXML::PrettyPrint;
use File::Find::Rule;

use Mojo::DOM;

use Plg::Projs::Html qw(
    html_pretty
);


use Base::Arg qw(
    hash_inject
    hash_update

    dict_update
);

use base qw(
    Base::Cmd
    Plg::Projs::Prj
);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub init {
    my ($self) = @_;

    my $root = getcwd();
    my $h = {
        cmd     => 'run',
        root    => $root,
        rootid  => basename($root),
    };

    hash_inject($self, $h);

    $self
        ->get_opt
        ->get_yaml
        # proj should be initialized by this moment
        ->Plg::Projs::Prj::init()
        ;

    return $self;
}

sub get_yaml {
    my ($self) = @_;

    my $f_yaml = $self->{f_yaml};
    return $self unless $f_yaml;

    my $data = LoadFile($f_yaml);

    foreach my $k (keys %$data) {
        $self->{$k} = $$data{$k};
    }

    return $self;
}

sub cmd_pretty {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $file = $ref->{file} || $self->{input};
    my $output = $ref->{output} || $self->{output};

    html_pretty({
       file   => $file,
       output => $output,
    });

    return $self;
}

sub print_help {
    my ($self) = @_;

    my $pack = __PACKAGE__;
    print qq{
        PACKAGES:
            $pack
        LOCATION:
            $0
        OPTIONS:
            --f_yaml -y  string    YAML control file
            --sec    -s  string    section
            --proj   -p  string    project name
        USAGE:
            PROCESS HTML FILE:
                perl $Script -p PROJ -s SEC -y YFILE
    } . "\n";
    exit 0;

    return $self;
}

sub get_opt {
    my ($self) = @_;

    return $self if $self->{skip_get_opt};

    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));

    my (@optstr, %opt);

    @optstr = (
        "f_yaml|y=s",
        "sec|s=s",
        "proj|p=s",
    );

    unless( @ARGV ){
        $self->print_help;
        exit 0;
    }else{
        GetOptions(\%opt,@optstr);
        $self->{opt} = \%opt;
    }

    hash_update($self, \%opt);

    return $self;
}

sub cmd_run {
    my ($self) = @_;

    #my @secs = $self->_secs_select
    my $sec = $self->{sec};

    my $dir_sec_new =  $self->_dir_sec_new({ sec => $sec });
    my $dir_sec_done =  $self->_dir_sec_done({ sec => $sec });

    my $rule = File::Find::Rule->new;

    my $dirs = [ $dir_sec_new, $dir_sec_done ];

    my ($html_file);
    foreach my $dir ( map { catfile($_, qw(html)) } @$dirs ) {
        next unless -d $dir;

        ($html_file) = $rule
            ->name('*.html')
            ->maxdepth(1)
            ->exec(sub {
               local $_ = shift;
               return /^we\.html$/ ? 1 : 0;
            })
            ->in($dir);
    }

    return $self unless $html_file;

    my $html_dir = dirname($html_file);
    chdir($html_dir);
    #current
    #
    my $p_file = sprintf(q{p.%s},basename($html_file));

    my $html = html_pretty({
        file => $html_file,
        output => $p_file,
    });
    my $dom = Mojo::DOM->new($html);

    my $i=0;

    $dom->find('meta, link, script')->map('remove');

    my $imgman = Plg::Projs::GetImg->new(
        skip_get_opt => 1,
        map { $_ => $self->{$_} } qw( root rootid proj sec ),
        cmd => 'fetch_uri',
    );

    my $j=0;
    $dom->find('image, img')->each(
        sub {
            my $href_save = $_->attr('data-savepage-href');
            return if !$href_save || $j == 1;
            $j++;
            $imgman->cmd_fetch_uri({ uri => $href_save });

            print qq{$j => $href_save} . "\n";
        }
    );

    $dom->find('style')->each(
        sub {
            $i++;
            my $txt = $_->content;
            my $css_file = "$i.css";
            write_file($css_file,$txt);
            #my $href = '/prj/sec/asset/' . $css_file;
            my $href = $css_file;
            $_->replace(sprintf('<link rel="stylesheet" href="%s">',$href));
        }
    );
    #print Dumper($c) . "\n";
    write_file($p_file,"$dom");

    return $self;
}

sub main {
    my ($self) = @_;

    $self->run_cmd;

    return $self;
}

1;
