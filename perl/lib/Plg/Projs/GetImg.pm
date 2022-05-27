
package Plg::Projs::GetImg;

use strict;
use warnings;

use utf8;

binmode STDOUT,':encoding(utf8)';

#use POSIX qw(locale_h);
#use locale;
#setlocale(LC_CTYPE,'UTF-8');
#

use FindBin qw($Bin $Script);
use DateTime;

use File::Basename qw(basename dirname);
use File::Which qw(which);
use File::Path qw(mkpath rmtree);

use File::stat;
use File::Find::Rule;
use File::Slurp::Unicode;

use File::Spec::Functions qw(catfile rel2abs);
use File::Path qw( mkpath rmtree );
use File::Copy qw( move copy );

use Data::Dumper::AutoEncode;
use Data::Dumper qw(Dumper);

use URI::Split qw(uri_split);

use LWP::Simple qw(getstore);
use LWP::UserAgent;
use Getopt::Long qw(GetOptions);

use YAML qw(LoadFile);
use String::Util qw(trim);

use Plg::Projs::Prj;
use Cwd qw(getcwd);

use Plg::Projs::GetImg::Fetcher;

use Base::Util qw(
  md5sum
);

use Base::Arg qw(
  dict_update
);

use Base::Data qw(
  d_path
);

use Image::Info qw(
    image_info
    image_type
);
use Image::ExifTool qw(ImageInfo);

use base qw(
    Base::Opt
    Base::Cmd
    Base::Logging
);

use Base::DB qw(
    dbi_connect

    dbh_do
    dbh_delete

    dbh_select
    dbh_select_join
    dbh_select_fetchone

    dbh_insert_hash
    dbh_update_hash

    dbh_base2info
);

use Base::Arg qw(
    hash_inject
    hash_update
);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub init_lwp {
    my ($self) = @_;

    my $lwp = LWP::UserAgent->new(
        agent      => ' Mozilla/5.0 (Windows NT 6.1; WOW64; rv:24.0) Gecko/20100101 Firefox/24.0',
        cookie_jar => {}
    );

    my $h = {
        lwp   => $lwp
    };

    hash_inject($self, $h);

    return $self;
}

sub init_root {
    my ($self) = @_;

    $self->{root} ||= getcwd();
    $self->{rootid} ||= basename($self->{root});

    return $self;
}

sub init_prj {
    my ($self) = @_;

    my ( $sec, $file, $proj, $root, $rootid );

    # cmd - single command
    # cmds - list of commands
    my ($cmd, $cmds) = @{$self}{qw(cmd cmds)};

    # need to have proj + root + rootid
    #   (1) no cmds, cmd = load_file
    #   (2) cmds, no need (each cmd may have required definitions)
    my $need_rrp;

    # single command defined
    unless ($cmds && $cmd) {
        $need_rrp = 1 if $cmd && $cmd eq 'load_file';
    }

    if ($file = $self->{file}) {
        ($proj, $sec) = ( basename($file)  =~ m/^(\w+)\.(.*)\.tex$/g );
        $root   = dirname($file);
        $rootid = basename($root);

        my $h = {
            proj   => $proj,
            sec    => $sec,
            root   => $root,
            rootid => $rootid,
        };
        hash_inject($self, $h);

    }elsif($self->{proj} && $self->{root}){
        $self->{rootid} = basename($self->{root});
    }

    if ($need_rrp) {
        if ($self->{root} && $self->{rootid} && $self->{proj}) {
            $self->_new_prj;
        }else{
            die qq{
                NOT DEFINED TOGETHER:
                    root && rootid && proj
            } . "\n";

        }
    }

    return $self;
}

sub init_db {
    my ($self) = @_;

    my $img_root = $self->{img_root};

    my $dbfile = catfile($img_root,qw(img.db));

    my $ref = {
        dbfile => $dbfile,
        attr   => {
        },
    };

    my $dbh = dbi_connect($ref);

    my $h = {
        dbfile   => $dbfile,
        img_root => $img_root,
    };

    hash_inject($self, $h);
    $self->{dbh} = $dbh;
    $Base::DB::DBH = $dbh;

#    if ($self->{reset}) {
        #$self
            #->db_drop
            #->db_create
            #;
    #}

    $self;
}

sub init_img_root {
    my ($self) = @_;

    my $img_root = $ENV{IMG_ROOT} // catfile($ENV{HOME},qw(img_root));
    #if ($self->{reset}) {
        #rmtree $img_root if -d $img_root;
    #}
    mkpath $img_root unless -d $img_root;

    $self->{img_root} = $img_root;

    $self;
}

sub db_drop {
    my ($self) = @_;

    dbh_do({
        q      => $self->{q}->{drop},
    });

    $self;
}

sub db_create {
    my ($self) = @_;

    my $q = $self->{q}->{create};
    dbh_do({
        q      => $q,
    });

    $self;
}

sub init_q {
    my ($self) = @_;

    my %q = (
        create => qq{
            CREATE TABLE IF NOT EXISTS imgs (
                url TEXT UNIQUE,
                url_parent TEXT,
                inum INTEGER,
                tags TEXT,
                rootid TEXT,
                proj TEXT,
                sec TEXT,
                img TEXT,
                caption TEXT,
                name TEXT,
                ext TEXT,
                type TEXT,
                md5 TEXT,
                name TEXT,
                name_uniq TEXT,
                width INTEGER,
                height INTEGER,
                width_tex TEXT,
                size INTEGER,
                mtime INTEGER
            );

            CREATE TABLE IF NOT EXISTS _info_imgs_tags (
                url TEXT NOT NULL,
                tag TEXT
            );
        },
        drop => qq{
            DROP TABLE IF EXISTS imgs;
        }
    );

    my $h = {
        q  => \%q,
    };

    hash_inject($self, $h);

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


sub init {
    my ($self) = @_;

    my $h = {
        cmd => 'load_file',
        ok   => [],
        fail => [],
    };

    hash_inject($self, $h);

    $self
        ->get_opt
        ->get_yaml
        ->init_root
        ->init_prj
        ->init_img_root
        ->init_q
        ->init_db
        ->init_lwp
        ;

    return $self;
}

sub get_opt {
    my ($self) = @_;

    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));

    my (@optstr, %opt);

    @optstr = (
        # image file, pattern, or directory
        #   sets
        #       cmd="add_images"
        #   calls
        #       cmd_add_images
        #           pic_add
        "add|a=s@",

        # config
        "config|c=s@",

        # yaml control file
        "f_yaml|y=s",

        # tex file
        "file|f=s",
        "proj|p=s",
        "root|r=s",
        "sec|s=s",
        # e.g. load_file
        "cmd|c=s",
        "reset",
        "reload",
        "debug|d",
        # queries to img.db
        "param=s@",
    );

    unless( @ARGV ){
        $self->print_help;
        exit 0;
    }else{
        GetOptions(\%opt,@optstr);
        $self->{opt} = \%opt;
    }

    hash_update($self, \%opt);

    if ($self->{add}) {
        $self->{cmd} = 'add_images';
    }

    return $self;
}

sub print_help {
    my ($self) = @_;

    my $pack = __PACKAGE__;
    print qq{
        ENVIRONMENT:
            IMG_ROOT   $ENV{IMG_ROOT}
            HTML_ROOT  $ENV{HTML_ROOT}
            PLG        $ENV{PLG}
        SEE ALSO:
            base#bufact#tex#list_img
            BufAct list_img
        PACKAGES:
            $pack
            Plg::Projs::GetImg::Fetcher
        LOCATION:
            $0
        OPTIONS:
            --f_yaml -y string YAML control file
            --add -a string (TODO) add image file, pattern or directory

            --file -f FILE string TeX file with urls
            --proj -p PROJ string
            --root -r ROOT string
            --sec  -s SEC  string

            --cmd  -c CMD  string    e.g. load_file

            --reset (DISABLED) reset database, remove image files
            --reload

            --debug -d

        USAGE:
            PROCESS SINGLE TEX-FILE:
                perl $Script -f TEXFILE
                perl $Script --file TEXFILE
            PROCESS WHOLE PROJECT:
                perl $Script -p PROJ -r ROOT
            DEBUGGING:
                perl $Script -p PROJ -r ROOT -d
                perl $Script -p PROJ -r ROOT --debug
    } . "\n";
    exit 0;

    return $self;
}

sub _new_prj {
    my ($self, $ref) = @_;
    $ref ||= {};

    my %n = map { $_ => $self->{$_} } qw(root rootid proj);
    %n = ( %n, imgman => $self, %$ref );
    my $prj = $self->{prj} = Plg::Projs::Prj->new(%n);

    return $prj;
}

sub _new_fetcher {
    my ($self, $ref) = @_;
    $ref ||= {};

    my %n = ( imgman => $self );
    $n{$_} = $self->{$_} for(qw( proj root rootid prj dbh img_root ));

    %n = ( %n, %$ref );

    my $ftc = Plg::Projs::GetImg::Fetcher->new(%n);

    return $ftc;
}

sub _ok {
    my ($self) = @_;

    return @{$self->{ok}};
}

sub _fail {
    my ($self) = @_;

    return @{$self->{fail}};
}

sub _db_imgs {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $tags  = $ref->{tags} || {};
    my $where = $ref->{where} || {};

    my $limit = $ref->{limit};

    my $r = {
       tbase => 'imgs',
       tbase_alias => 'i',

       on_key => 'url',

       keys => [qw( tags )],
       key2col => { tags => 'tag' },

       f => [qw( url )],

       tags => $tags,

       where => $where,
    };
    $r->{limit} = $limit if $limit;

    my $list = dbh_select_join($r);

    return $list;
}

sub _fs_find_imgs {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $exts = $ref->{exts} || [qw( jpg jpeg png )];
    my $dirs = $ref->{dirs} || [];
    return () unless $dirs && @$dirs;

    my $limit = $ref->{limit} || 0;

    my $find_opts = $ref->{find} || {};
    my $max_depth = $find_opts->{max_depth} || 0;

    my @glob = map { "*.$_" } @$exts;

    my $rule = File::Find::Rule->new;
    $rule->name(@glob);
    $rule->maxdepth($max_depth) if $max_depth;

    my @imgs = $rule->in(@$dirs);
    @imgs = sort { stat($a)->mtime <=> stat($b)->mtime } @imgs;

    @imgs = splice(@imgs, 0 => $limit) if $limit;

    return @imgs;
}

sub _subs_url {
    my ($self, $ref) = @_;
    $ref||={};

    my ($url, $img_file, $sec) = @{$ref}{qw( url img_file sec )};
    my $lwp  = $self->{lwp};

    my @subs = (
        sub {
            my $curl = which 'curl';
            return unless $curl;

            print qq{try: curl} . "\n";

            my $url_s = $^O eq 'MSWin32' ? qq{"$url"} : qq{"$url"};

            my $cmd = qq{ $curl -o "$img_file" $url_s };
            my $x = qx{ $cmd 2>&1 };
            $self->debug(["Command:", $x]);
            return 'curl';
        },
        sub {
            print qq{try: lwp} . "\n";

            my $res = $lwp->mirror($url,$img_file);
            unless ($res->is_success) {
                my $r = {
                    msg         => 'LWP Error',
                    url         => $url,
                    status_line => $res->status_line,
                };
                warn Dumper($r) . "\n";
            }
            return 'lwp';
        },
        sub {
            my $r = {
                url    => $url,
                proj   => $self->{proj},
                rootid => $self->{rootid},
                sec    => $sec,
            };
            warn sprintf('URL Download Failure: %s',Dumper($r)) . "\n";
        }
  );
  return @subs;

}

sub cmd_count {
    my ($self) = @_;

    my $q = qq{ SELECT COUNT(*) FROM imgs };
    my $count = dbh_select_fetchone({ q => $q });
    print qq{$count} . "\n";
}

sub cmd_query {
    my ($self) = @_;

    my $q = $self->{query};

    my $ref = {
        q => $q,
        p => [],
    };

    my ($rows, $cols) = dbh_select($ref);

    return $self;
}

sub pre_cmd {
    my ($self) = @_;

    # ---------------------------------------------------
    my $data = $self->{data} || {};

    my ($cmd, $cmd_full, $cmd_spec) = @{$self}{qw( cmd cmd_full cmd_spec )};

    $data->{$cmd_full} ||= {};
    my $cmd_data = {};

    if (grep { /^\@vars$/ } @$cmd_spec) {
       my $d = $self->{'vars'}->{$cmd} ||= {};
       dict_update($d, $cmd_data);
       return $self;
    }

    my $vars = $self->{vars} || {};
    dict_update($cmd_data, d_path( $vars, $cmd ));
    dict_update($cmd_data, $data->{$cmd_full} );
    $self->{cmd_data} = $cmd_data;
    # ---------------------------------------------------

    for(@$cmd_spec){
        /^\@(\w+)\{(.*)\}/ && do { $cmd_data->{$1} = $2; };
    }

    return $self;
}

sub cmd_load_file {
    my ($self) = @_;

    my ($cmd_data) = @{$self}{qw( cmd_data )};

    $self->load_file($cmd_data);

    return $self;
}

sub cmd_db_fk_create {
    my ($self) = @_;

    my ($cmd_data) = @{$self}{qw( cmd_data )};

    my ($sec, $proj) = @{$cmd_data}{qw( sec proj)};
    $self->{proj} = $proj;

    my $prj = $self->_new_prj({ proj => $proj });

    my $fk = q{ FOREIGN KEY(file) REFERENCES projs(file) ON DELETE CASCADE ON UPDATE CASCADE };
    my $q_tree = qq{
        CREATE TEMPORARY TABLE temp_tree AS
        SELECT *
        FROM tree_children;

        DROP TABLE IF EXISTS tree_children;

        CREATE TABLE tree_children (
            proj TEXT NOT NULL,
            file TEXT NOT NULL,
            sec TEXT NOT NULL,
            child TEXT NOT NULL,
            FOREIGN KEY(file) REFERENCES projs(file) ON DELETE CASCADE ON UPDATE CASCADE
        );

        INSERT INTO tree_children (proj, file, sec, child)
        SELECT proj, file, sec, child
        FROM temp_tree;
    };

    my $q_tags = qq{
        CREATE TEMPORARY TABLE temp_tags AS
        SELECT *
        FROM _info_projs_tags;

        DROP TABLE IF EXISTS _info_projs_tags;

        CREATE TABLE _info_projs_tags (
            file TEXT NOT NULL,
            tag TEXT NOT NULL,
            FOREIGN KEY(file) REFERENCES projs(file) ON DELETE CASCADE ON UPDATE CASCADE
        );

        INSERT INTO _info_projs_tags (file, tag)
        SELECT file, tag FROM temp_tags;
    };

    return $self;
}

sub cmd_db_fk_check {
    my ($self) = @_;

    my ($cmd_data) = @{$self}{qw( cmd_data )};

    my ($sec, $proj) = @{$cmd_data}{qw( sec proj)};
    $self->{proj} = $proj;

    my $prj = $self->_new_prj({ proj => $proj });

    my ($rows, $cols) = dbh_select({
        dbh => $prj->{dbh},
        q => q{ PRAGMA foreign_key_check; },
    });
    my( @secs, @files);
    foreach my $rw (@$rows) {
        my $fkid = $rw->{fkid};
        next if $fkid;

        my $sec;
        my ($rowid, $table, $parent) = @{$rw}{qw(rowid table parent)};

      #  my $r = {
            #dbh => $prj->{dbh},
            #q => qq( SELECT p.sec FROM projs p INNER JOIN $table i ON p.file = i.file WHERE i.rowid = ?),
            #p => [$rowid],
        #};
        #my $sec = dbh_select_fetchone($r);

        my $r = {
            dbh => $prj->{dbh},
            q => qq( SELECT file FROM $table WHERE rowid = ?),
            p => [$rowid],
        };
        my $file = dbh_select_fetchone($r);
        my $file_path = catfile($prj->{root},$file);
        unless (-f $file_path) {
           dbh_delete({
              dbh => $prj->{dbh},
              t => $table,
              w => { rowid => $rowid },
           });
           next;
        }

        push @files, $file;

    }

    return $self;
}

sub cmd_load_sec {
    my ($self) = @_;

    my ($cmd_data) = @{$self}{qw( cmd_data )};

    my ($root, $rootid) = @{$self}{qw( root rootid )};

    my ($sec, $proj) = @{$cmd_data}{qw( sec proj)};
    $self->{proj} = $proj;
    return $self unless $sec && $proj;

    # array
    my ($tags) = @{$cmd_data}{qw( tags )};
    $tags ||= [];

    my $prj = $self->_new_prj({ proj => $proj });
    my $sec_data = $prj->_sec_data({
        proj => $proj,
        sec  => $sec,
    });
    my $sec_url = $sec_data->{url};

    # update database with child/parents info from \ii{...} lines
    $prj->sec_load({ proj => $proj, sec => $sec });

    # current cmd data
    my $lts_data = catfile($ENV{LTS_DATA});
    my $new_dir  = catfile($lts_data,qw(new));

    my $dir_sec_new = catfile($new_dir,$sec);
    return $self unless -d $dir_sec_new;


    my $map = {
       orig => {
         tex_head => [ '', '\qqSecOrig', '' ],
         dir => $dir_sec_new,
         tgx => [qw( orig.post scrn )],
         sec_suffix => 'orig',
         scheme => { last => 2 },
       },
       cmtx => {
         tex_head => [ '', '\qqSecCmtScr', '' ],
         dir => catfile($dir_sec_new, qw(cmt)),
         tgx => [qw( orig.cmt scrn )],
         sec_suffix => 'cmtx',
         scheme => { last => 2 },
       },
    };

    foreach my $x (qw( orig cmtx )) {
        my $mapx = $map->{$x};

        my $dir = $mapx->{dir};
        next unless -d $dir;

        my $tgx   = $mapx->{tgx} || [];
        my $headx = $mapx->{tex_head} || [];
        my $scheme = $mapx->{scheme} || {};

        my $secx  = $mapx->{sec_suffix} || [];
        my $sec_child = sprintf(qq{%s.%s}, $sec, $secx);

        my @imgs = $self->_fs_find_imgs({
           find  => { max_depth => 1 },
           dirs  => [ $dir ],
           #limit => 5,
        });

        # does child section have any pictures already in database?
        my $child_pics = $prj->_sec_data_pics({
           proj => $proj,
           sec  => $sec_child,
           cols => [qw( md5 size )],
        });

        # we import into database all screenshots on the filesystem
        foreach my $img_path (@imgs) {
            $self->pic_add({
                file => $img_path,
                tags => [ @$tgx, @$tags ],

                proj   => $proj,
                sec    => $sec,
                rootid => $rootid,
                url_parent => $sec_url,

                mv => 0,
            });
        }

        # we grab all screenshots already in the database
        my $img_urls = $self->_db_imgs({
           tags => { and => $tgx },
           where => {
             sec        => $sec,
             proj       => $proj,
             rootid     => $rootid,
             url_parent => $sec_url,
           }
        });

        next unless @$img_urls;

        $prj->sec_delete({
            sec    => $sec_child,
            proj   => $proj,
        });

        $prj->sec_new({
            sec    => $sec_child,
            proj   => $proj,
            parent => $sec,
            append => $headx
        });

        $prj->sec_import_imgs({
            sec    => $sec_child,
            proj   => $proj,
            imgs   => $img_urls,
            scheme => $scheme,
        });

        $prj->sec_insert_child({
            sec   => $sec,
            proj  => $proj,
            child => $sec_child,
        });

    }

    return $self;
}

sub pic_add {
    my ($self, $ref) = @_;
    $ref ||= {};

    # local file to be imported
    my $img_file_local = $ref->{file};
    return $self unless -f $img_file_local;

    my $stat_local = stat($img_file_local);
    my $mtime_local = $stat_local->mtime;
    my $size = $stat_local->size;

    # list of saved img urls
    my $img_urls = $ref->{img_urls};

    # pic data
    my ( $tags, @tags, $tags_s );

    $tags = $ref->{tags} || [];
    @tags = ref $tags eq 'ARRAY' ? @$tags : map { trim($_) } grep { length } split ',' => $tags;
    $tags_s = join ',' => @tags;

    # move if 1
    my $mv = $ref->{mv};

    my $dt = DateTime->now;
    my $t = $dt->strftime('%d_%m_%y.%H.%M.%S');

    my $md5    = md5sum($img_file_local);
    my $inf_local    = image_info($img_file_local);
    my $url_tm = sprintf(q{tm://%s@%s}, $t, $md5);

    my $exif_local = ImageInfo($img_file_local);

    my ($width, $height, $ext) = @{$inf_local}{qw( width height file_ext )};

    my $r = {
        t => qq{ imgs },
        q => q{ SELECT COUNT(*) FROM imgs },
        w => { md5 => $md5 },
    };

    # do not insert image with the same md5
    my $cnt = dbh_select_fetchone($r);
    if ($cnt) {
      rmtree $img_file_local if $mv;

      return $self;
    }

    my $inum = dbh_select_fetchone({ q => 'SELECT MAX(inum) FROM imgs' });
    $inum++;

    my $img = qq{$inum.$ext};
    my $img_file = catfile($self->{img_root}, $img);

    my $ins = {
       url    => $url_tm,
       inum   => $inum,
       img    => $img,
       ext    => $ext,
       md5    => $md5,
       width  => $width,
       height => $height,
       size   => $size,
       mtime  => $mtime_local,
    };

    $ins->{tags} = $tags_s if $tags_s;

    foreach my $x (qw( proj sec rootid url_parent )) {
       next unless defined $ref->{$x};

       $ins->{$x} = $ref->{$x};
    }

    copy($img_file_local, $img_file);

    my ($ok, $fs_ok) = (1, 1);

    while (1) {
       $fs_ok &&= -f $img_file;

       $ok &&= $fs_ok;
       last unless $fs_ok;

       $ok &&= eval {
          dbh_insert_hash({
              t => 'imgs',
              i => q{ INSERT OR REPLACE },
              h => $ins,
          });
       };
       $@ && do { $ok = 0; warn $@; };

       $ok &&= eval {
           dbh_base2info({
              'tbase'  => 'imgs',
              'bwhere' => { url => $url_tm },
              'jcol'   => 'url',
              'b2i'    => { 'tags' => 'tag' },
              'bcols'  => [qw( tags )],
           });
       };
       $@ && do { $ok = 0; warn $@; };

       unless ($ok) {
          rmtree $img_file;

       }elsif($mv){
          rmtree $img_file_local;
       }

       last;
    }

    if ($ok) {
      if ($img_urls && ref $img_urls eq 'ARRAY') {
         push @$img_urls, $url_tm;
      }
      print "(pic_add) OK: Import: $img_file_local" . "\n";
      print "(pic_add) " . Dumper({ inum => $inum, size => $size }) . "\n";
    }

    return $self;
}

sub cmd_db_add_md5 {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $img_root = $self->{img_root};

    my ($rows, $cols, $q, $p) = dbh_select({
       t => 'imgs',
       q => q{ SELECT url, md5, inum, img FROM imgs WHERE md5 IS NULL },
       limit => 30000,
    });

    my @eq;
    foreach my $rw (@$rows) {
        my ($inum, $img, $md5_db) = @{$rw}{qw(inum img md5)};
        my $img_file = catfile($img_root, $img);
        next unless -f $img_file;

        my $md5 = md5sum($img_file);
        my $inf = image_info($img_file);
        my ($width, $height, $ext) = @{$inf}{qw( width height file_ext )};

        my $ref = {
            t => 'imgs',
            h => {
                #'md5'    => undef,
                'md5'    => $md5,
                'height' => $height,
                'width'  => $width,
            },
            w => { inum => $inum },
        };
        dbh_update_hash($ref);
    }

    return $self;
}


sub cmd_add_images {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($cmd, $cmd_data, $cmd_full, $cmd_spec) = @{$self}{qw( cmd cmd_data cmd_full cmd_spec )};
    # current cmd data
    $cmd_data ||= $ref->{add} || $self->{add};

    # image file extensions
    my $exts = [qw( jpg jpeg png )];

    my (@files_add, @paths_add);
    my ($max_files, $tags, $mv);

    my $find_opts ||= {};
    my $max_depth;

    if (ref $cmd_data eq "ARRAY"){
       @paths_add = @$cmd_data;
    }elsif(ref $cmd_data eq "HASH"){
       @paths_add = @{$cmd_data->{paths} || []};

       ($max_files, $tags, $mv) = @{$cmd_data}{qw( max_files tags mv )};

       $exts = $cmd_data->{exts} || $exts;

       $find_opts = $cmd_data->{find} || {};
       $max_depth = $find_opts->{max_depth} || 0;
    # single file
    }elsif(!ref $cmd_data){
       @paths_add = ( $cmd_data );
    }

    @files_add = map { s/^~/$ENV{HOME}/g; rel2abs($_) } @paths_add;

    my $file_num = 0;
    while (@files_add) {
       my $path = shift @files_add;

       unless (ref $path) {
           -d $path && do {

              my @imgs = $self->_fs_find_imgs({
                 'exts'  => $exts,
                 'find'  => $find_opts,
                 'dirs'  => [ $path ],
              });

              push @files_add, @imgs;

              next;
           };

           -f $path && do {
               $file_num++;

               my $r_add = { file => $path };
               $r_add->{tags} = $tags if $tags;
               $r_add->{mv} = $mv if $mv;

               $self->pic_add($r_add);
               last if $max_files && $file_num == $max_files;

               next;
           };
       }
    }

    return $self;
}

sub load_file {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($file, $file_bn, $sec, $proj, $root);

    # objects
    my ($prj);

    $root = $self->{root};
    $prj  = $self->{prj} || $self->_new_prj;

    $file = $self->_opt_($ref,'file');
    $sec  = $self->_opt_($ref,'sec');
    $proj = $self->_opt_($ref,'proj');

    my $atend = sub { $self->info_ok_fail };

    if ($sec) {
        my $sec_data = $prj->_sec_data({
            sec  => $sec,
            proj => $proj,
        });
        $file_bn ||= $sec_data->{file};
        $file = catfile($self->{root}, $file_bn);
    }

    unless ($file) {
        my @files = $prj->_files;

        foreach(@files){
            my $file = catfile($root,$_->{file});
            my $sec  = $_->{sec};

            next unless -f $file;

            $self->load_file({
                file       => $file,
                sec        => $sec,
                skip_atend => 1,
            });
        }

        $atend->();

        return $self;
    }
    $file_bn = basename($file);

    my $img_root = $self->{img_root};

    $self->debug(qq{Reading:\n\t$file_bn});
###read_file @lines
    my @lines = read_file $file;

    my %n = (
       file => $file,
       sec  => $sec,
       proj  => $proj,
    );
    my $ftc = $self->_new_fetcher(\%n);

    $ftc
        ->f_read
        ->loop;

    $atend->() unless $ref->{skip_atend};

    return $self;
}

sub info_ok_fail {
    my ($self) = @_;

    my @m;
    if ($self->_ok) {
        my $cnt = scalar $self->_ok;
        push @m,
            sprintf('SUCCESS: %s images', $cnt)
            ;

        print join("\n",@m) . "\n";

    } elsif ($self->_fail) {
        my $cnt = scalar $self->_fail;
        push @m,
            'FAIL dump: ' . $cnt,
            Dumper([ map { { url => $_->{url}, sec => $_->{sec} } } $self->_fail ]),
            sprintf('FAIL: %s images', $cnt),
            ;

        warn join("\n",@m) . "\n";
    }else{
        push @m,
            sprintf('NO IMAGES! %s',$self->{proj} ? 'proj: ' . $self->{proj} : '');
        print join("\n",@m) . "\n";
    }

    return $self;
}

sub run {
    my ($self) = @_;

    my $cmds = $self->{cmds} || [ $self->{cmd} ];

    foreach my $cmd (@$cmds) {
        local $_ = $cmd;

        my ($cmd_short, $cmd_spec_str) = (/^(\w+)(?:|\s+(.*))$/);
        $cmd_spec_str ||= '';
        my $cmd_spec = [ split ' ' => $cmd_spec_str ];

        hash_update($self, {
           cmd      => $cmd_short,
           cmd_full => $cmd,
           cmd_spec => $cmd_spec,
        });

        $self
            ->pre_cmd
            ->run_cmd;
    }

    return $self;
}

1;



