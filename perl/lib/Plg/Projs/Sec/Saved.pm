
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
use HTML5::DOM;

use CSS::Tidy 'tidy_css';

use MIME::Base64 qw(decode_base64);
use Base::Util qw(
    md5sum
);

use Plg::Projs::Html qw(
    html_pretty
);

use Base::DB qw(
    dbh_insert_update_hash
    dbh_update_hash
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
    #my $dom = Mojo::DOM->new($html);
    my $parser = HTML5::DOM->new();

    my $dom = $parser->parse($html);

    my $i=0;

    $dom->find('meta, script, link')->map('remove');

    my $imgman = Plg::Projs::GetImg->new(
        skip_get_opt => 1,
        map { $_ => $self->{$_} } qw( root rootid proj sec ),
        cmd => 'fetch_uri',
    );

    my $j=0;
    $DB::single = 1;
    $dom->find('image, img')->each(
        sub {
            my ($node, $index) = @_;
            local $_ = $node;
            my ($href_save, $href_img);

            my $href_name;
            foreach my $x (qw(href src)) {
	            $href_save ||= $_->attr('data-savepage-' . $x);
	            $href_img ||= $_->attr($x);

                if ($href_img && $href_save){
                    $href_name = $x; last;
                }
            }

            #return if $j == 100;
            return unless $href_name && $href_save && $href_img;

            $j++;

            if ($href_img =~ /^data:image\/(?<type>png|jpeg);base64,(?<data>.*)/) {
                my ($data, $type) = @+{qw(data type)};
                my $ext = $type eq 'jpeg' ? 'jpg' : $type;
                my $decoded = decode_base64($data);
                my $f = qq{$j.$ext};

                open my $fh, '>', $f or die $!;
                binmode $fh;
                print $fh $decoded;
                close $fh;

                my $md5 = md5sum($f);

                my $img_db;
                my $step = 0;
                while(1) {
#                    dbh_update_hash({
                        #dbh => $imgman->{dbh},
                        #t => 'imgs',
                        #h => { #map { $_ => $self->{$_} } qw( rootid proj sec ), },
                        #w => { md5 => $md5 },
                    #});

                    $img_db = $imgman->_db_img_one({
                        fields => [qw( url inum img size proj sec )],
                        where => { md5 => $md5 }
                    });
                    last if $img_db || $step == 1;

                    $imgman->pic_add({
                        file => $f,
                        url => $href_save,
                        ins_db => {
                            map { $_ => $self->{$_} } qw( rootid proj sec ),
                        },
                    });

                    $step++;
                }

                if ($img_db) {
                    my $img = $img_db->{img};
                    my $href_db = 'file://' . join('/', $imgman->{img_root}, $img);
                    $_->attr({ $href_name => $href_db });
                    delete $_->{'data-savepage-' . $href_name };
                }
             }
        }
    );

    $j=0;
    $dom->find('style')->each(
        sub {
            local $_ = shift;
            $j++;
            my $css_txt = $_->text;
            $css_txt = tidy_css($css_txt);

            my $css_file = "$j.css";
            write_file($css_file, $css_txt);
            #my $href = '/prj/sec/asset/' . $css_file;
            my $href = $css_file;
            my $link = $dom->createElement('link');
            $link->attr({ rel => 'stylesheet', href => $href });
            $_->replace($link);
        }
    );
    write_file($p_file, $dom->html);

    return $self;
}

sub main {
    my ($self) = @_;

    $self->run_cmd;

    return $self;
}

1;

