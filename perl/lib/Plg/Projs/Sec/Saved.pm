
package Plg::Projs::Sec::Saved;

use utf8;
use strict;
use warnings;

use Encode;
binmode STDOUT,':encoding(utf8)';

use Data::Dumper qw(Dumper);
use FindBin qw($Bin $Script);
use Getopt::Long qw(GetOptions);

#use YAML qw(LoadFile DumpFile Dump);
use YAML::XS qw(LoadFile DumpFile Dump);

use URL::XS qw(parse_url);
use URI;

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
use File::Path qw(mkpath rmtree);

use HTML5::DOM;

#use Mojo::DOM;
#my $dom = Mojo::DOM->new($html);

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
    varval
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
        ->init_imgman
        ;
    $DB::single = 1;

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

sub _sec_html_file {
    my ($self,$ref) = @_;
    $ref ||= {};

    my $sec = $ref->{sec} || $self->{sec};

    my $dir_sec_new  =  $self->_dir_sec_new({ sec => $sec });
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

    return $html_file;
}

sub init_imgman {
    my ($self) = @_;

    $self->{imgman} = Plg::Projs::GetImg->new(
        skip_get_opt => 1,
        map { $_ => $self->{$_} } qw( root rootid proj sec ),
        cmd => 'fetch_uri',
    );

    return $self;
}

sub cmd_run {
    my ($self) = @_;

    #my @secs = $self->_secs_select
    my ($sec, $secs) = @{$self}{qw( sec secs )};
    $secs ||= [];

    unless ($sec) {
        foreach my $ss (@$secs) {
            $self->{sec} = $ss;
            $self->cmd_run;
        }
        return $self;
    }

    print qq{[Saved] processing section => $sec } . "\n";

    my $html_file = $self->_sec_html_file;
    return $self unless $html_file;

    my $html_dir = $self->{html_dir} = dirname($html_file);
    chdir($html_dir);

    dict_update($self,{
        p_file_orig => $html_file,
        p_file_view => sprintf(q{p.%s},basename($html_file)),
        p_file_unwrap => sprintf(q{p.unwrap.%s},basename($html_file)),

        p_file_parse => sprintf(q{p.parse.%s},basename($html_file)),
        p_file_content => sprintf(q{p.parse.content.%s},basename($html_file)),
        p_file_article => sprintf(q{p.parse.article.%s},basename($html_file)),
    });

    $self->{parser} ||= HTML5::DOM->new();

    unless (-f $self->{p_file_view}) {
        $self->fs_write_view;
    }

    unless (-f $self->{p_file_unwrap}) {
        $self->fs_write_unwrap;
    }

    $self->fs_write_parse;


    #write_file($p_file, $dom->html);
    #html_pretty({
        #file => $p_file,
        #output => $p_file,
    #});


    return $self;
}

sub fs_write_parse {
    my ($self, $ref) = @_;
    $ref ||= {};

    print qq{[Saved] fs_write_parse} . "\n";

    my $html = read_file $self->{p_file_unwrap};
    $self->{dom} = $self->{parser}->parse($html);

    $self
        ->do_clean_class
        ->do_a_href
        ->do_write2fs({ file => $self->{p_file_parse}, pretty => 1 })
        ;

    return $self;
}

sub fs_write_unwrap {
    my ($self, $ref) = @_;
    $ref ||= {};

    print qq{[Saved] fs_write_unwrap} . "\n";

    my $html = read_file $self->{p_file_view};
    $self->{dom} = $self->{parser}->parse($html);

    $self
       ->do_unwrap
       ->do_write2fs({ file => $self->{p_file_unwrap}, pretty => 1 });

    return $self;
}

sub fs_write_view {
    my ($self, $ref) = @_;
    $ref ||= {};

    print qq{[Saved] fs_write_view } . "\n";

    my $html = html_pretty({ file => $self->{p_file_orig} });
    $self->{dom} = $self->{parser}->parse($html);

    $self
        ->do_meta
        ->do_css
        ->do_img
        ->do_write2fs({ file => $self->{p_file_view}, pretty => 1 });

    return $self;
}

sub do_img {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $dom = $ref->{dom} || $self->{dom};
    my $imgman = $self->{imgman};

    my $sec = $self->{sec};
    my $sd = $self->_sec_data({ sec => $sec });

    my $url_parent = $sd->{url};
    my $db_upd = $self->{db_upd};

    my $ins_db = {
        ( map { $_ => $self->{$_} } qw( rootid proj sec ) ),
        url_parent => $url_parent,
    };

    my $img_dir = 'imgs';
    mkpath $img_dir unless -d $img_dir;

    my $j=0;
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
                my $f = catfile($img_dir, qq{$j.$ext});

                open my $fh, '>', $f or die $!;
                binmode $fh;
                print $fh $decoded;
                close $fh;

                my $md5 = md5sum($f);

                my $img_db;
                my $step = 0;
                while(1) {
                    if ($db_upd) {
                        dbh_update_hash({
                            dbh => $imgman->{dbh},
                            t => 'imgs',
                            h => $ins_db,
                            w => { md5 => $md5 },
                        });
                    }

                    $img_db = $imgman->_db_img_one({
                        fields => [qw( url inum img size proj sec )],
                        where => { md5 => $md5 }
                    });
                    last if $img_db || $step == 1;

                    $imgman->pic_add({
                        file   => $f,
                        url    => $href_save,
                        ins_db => $ins_db,
                        mv     => 1,
                        tags   => [qw( fb.saved )],
                    });

                    $step++;
                }

                if ($img_db) {
                    my $img = $img_db->{img};
                    my $href_db = 'file://' . join('/', $imgman->{img_root}, $img);
                    $_->attr({ $href_name => $href_db });
                    $_->removeAttr('data-savepage-' . $href_name );
                }
             }
        }
    );

    return $self;
}

my $i = 0;
sub unwrap {
    my ($self, $node, $tags) = @_;
    $tags ||= [qw(div)];

    #return $self if $i > 100;
    $i++;

    my ($len, $txt, $tag);
    $len = $node->children->length;
    $txt = $node->text;
    $tag = $node->tag;

    unless($len || $txt) {
       if (grep { /^$tag$/ } qw(span div)) {
           #print qq{$i => remove} . "\n";
           my $parent = $node->parent;
           $node->remove();

           $self->unwrap($parent) if $parent;
           return $self;
       }
    }

    if ($len == 1) {
        my $child = $node->children->[0];
        if ($tag eq 'div' && $child->tag eq 'div') {
            my $class_list = $node->classList;
            my $attr = $node->attr;
            while(my($k,$v) = each %$attr){
                next if $k eq 'class';

                if ($k eq 'style') {
                    my $p_style = $node->attr('style');
                    my $c_style = $child->attr('style');
                    next unless $p_style || $c_style;

                    $c_style = join ';' => (
                        $p_style ? $p_style : (),
                        $c_style ? $c_style : (),
                    );
                    $child->attr('style' => $c_style);

                }
                $child->attr({ $k  => $v });
            }
            #print Dumper($attr) . "\n";

            $class_list->each(sub {
               my $class = shift;
               $child->classList->add($class);
               #print Dumper($class) . "\n";
            });

            $node->parent->replaceChild($child => $node);
            $node = $child;
        }
        $self->unwrap($child);
        return $self;
    }

    return $self unless $node;
    $node->children->each( sub{
       local $_ = shift;
       my $tag = $_->tag;
       #return unless grep { /^$tag$/ } @$tags;
       #return unless $_->tag eq 'div';

       $self->unwrap($_);

       return $_;
    });

    return $self;
}

sub do_meta {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $dom = $ref->{dom} || $self->{dom};

    $dom->find('meta, script, link')->map('remove');

    my $meta = $dom->createElement('meta');
    $meta->attr({
        'http-equiv' => "Content-Type",
        'content'  => "text/html; charset=utf-8",
    });
    $dom->at('head')->append($meta);

    return $self;
}

sub do_a_href {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $dom = $ref->{dom} || $self->{dom};

    my $j=0;
    my @urls;
    $dom->find('a[href]')->each(
        sub {
            my ($node, $index) = @_;
            #return if $j > 10;

            local $_ = $node;
            my $href = $_->{href};
            my ($parsed,$uri);
            eval {
                $uri = URI->new($href);
                $parsed = parse_url($href);

                if ($uri && $parsed) {
                    $parsed->{query} = $uri->query;
                }
            };
            push @urls,
              {     url => $href,
                    parsed => $parsed
              };

            $j++;
        }
    );
    my $cwd = getcwd();
    chdir $self->{root};
    my $ofile = 'saved.out.yaml';
    my $dmp = Dumper([@urls]) . "\n";
    #my $yml = Dump({ urls => [@urls] });
    write_file($ofile, $dmp);
    chdir $cwd;

    return $self;
}

sub do_clean_class {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $dom = $ref->{dom} || $self->{dom};

    print qq{[clean_class]} . "\n";

    my $remove_a = varval('config.dom.remove.node' => $self) || [];
    my $remove = join(", " => @$remove_a);
    if ($remove) {
        $dom->find($remove)->each(
           sub {
               my $node = shift;
               $node->remove();
           }
        );
    }

    my $remove_class_a = varval('config.dom.remove.class' => $self) || [];
    my $remove_class = join(", " => @$remove_class_a);
    if ($remove_class) {
        $dom->find($remove_class)->each(
           sub {
               my $node = shift;
               $node->removeAttr('class');
           }
        );
    }

    my $msg_a = varval('config.dom.match.post' => $self) || [];
    my $msg = join(", ",@$msg_a);

    my $cnt;
    $dom->find($msg)->each(
        sub {
           my $node = shift;
           #$cnt = $node->textContent;
           $cnt = $node->html;
           #print Encode::encode('utf8',$node->textContent) . "\n";
        }
    );
    write_file($self->{p_file_content}, $cnt) if $cnt;

    my @article;
    $dom->find('div[role="article"]')->each(
        sub {
           my $node = shift;
           push @article, $node->html;
           #print Encode::encode('utf8',$node->textContent) . "\n";
        }
    );

    write_file($self->{p_file_article}, join("\n",@article) . "\n") if @article;

    #"jsc_c_x

    return $self;
}

sub do_unwrap {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $dom = $ref->{dom} || $self->{dom};

    $self->unwrap($dom->at('body'));

    return $self;
}

sub do_write2fs {
    my ($self, $ref) = @_;
    $ref ||= {};

    chdir($self->{html_dir});

    my $dom = $ref->{dom} || $self->{dom};
    my $file = $ref->{file};

    my $html = $dom->html;
    $html = $ref->{pretty} ? html_pretty({ html => $html }) : $html;

    write_file($file, $html);

    return $self;
}

sub do_css {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $dom = $ref->{dom} || $self->{dom};

    my $css_dir = 'css';
    mkpath $css_dir unless -d $css_dir;

    my $j = 0;
    $dom->find('style')->each(
        sub {
            local $_ = shift;
            $j++;
            my $css_txt = $_->text;
            $css_txt = tidy_css($css_txt);

            my $css_file = "css/$j.css";
            write_file($css_file, $css_txt);
            #my $href = '/prj/sec/asset/' . $css_file;
            my $href = $css_file;
            my $link = $dom->createElement('link');
            $link->attr({
                rel  => 'stylesheet',
                type => 'text/css',
                href => $href
            });
            $_->replace($link);
        }
    );

    return $self;
}

sub main {
    my ($self) = @_;

    $self->run_cmd;

    return $self;
}

1;

