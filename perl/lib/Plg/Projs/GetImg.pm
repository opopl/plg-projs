
package Plg::Projs::GetImg;

use strict;
use warnings;

use utf8;

binmode STDOUT,':encoding(utf8)';

#use POSIX qw(locale_h);
#use locale;
#setlocale(LC_CTYPE,'UTF-8');

use Plg::Projs::Prj;
use Cwd qw(getcwd);

use Plg::Projs::GetImg::Fetcher;

use File::Spec::Functions qw(catfile);
use File::Path qw( mkpath rmtree );
use File::Copy qw( move );

use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use File::Which qw(which);  

use URI::Split qw(uri_split);

use LWP::Simple qw(getstore);
use LWP::UserAgent;
use Getopt::Long qw(GetOptions);

use Image::Info qw(
    image_info
    image_type
);

use base qw(
    Base::Opt
    Base::Cmd
    Base::Logging
);

use Base::DB qw( 
    dbi_connect 
    dbh_do
    dbh_select
    dbh_select_fetchone
    dbh_insert_hash
);

use Base::Arg qw( 
    hash_inject
    hash_update
);

use Data::Dumper::AutoEncode;
use Data::Dumper qw(Dumper);
use File::Slurp::Unicode;

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

    return $self;
}

sub init_prj {
    my ($self) = @_;

    my ( $sec, $file, $proj, $root, $rootid );

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

    if ($self->{root} && $self->{rootid} && $self->{proj}) {
        $self->{prj} = Plg::Projs::Prj->new(
            root   => $self->{root},
            rootid => $self->{rootid},
            proj   => $self->{proj},
        );
    }else{
        die qq{
            NOT DEFINED TOGETHER: 
                root && rootid && proj
        } . "\n";
        
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

    if ($self->{reset}) {
        $self
            ->db_drop
            ->db_create
            ;
    }

    
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
                md5 TEXT UNIQUE,
                name TEXT,
                name_uniq TEXT,
                width INTEGER,
                height INTEGER,
                width_tex TEXT
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
        "query|q=s",
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

    return $self;    
}

sub print_help {
    my ($self) = @_;

    my $pack = __PACKAGE__;
    print qq{
        SEE ALSO:
            base#bufact#tex#list_img 
            BufAct list_img
        PACKAGE:
            $pack
        LOCATION:
            $0
        USAGE:
            PROCESS SINGLE TEX-FILE:
                perl $Script -f TEXFILE 
                perl $Script --file TEXFILE 
            PROCESS WHOLE PROJECT:
                perl $Script -p PROJ -r ROOT 
            DEBUGGING:
                perl $Script -p PROJ -r ROOT -d
                perl $Script -p PROJ -r ROOT --debug
            RESET DATABASE, REMOVE IMAGE FILES:
                perl $Script --reset
            QUERY IMAGE DATABASE:
                perl $Script --cmd query -q "select count(*) from imgs" 
                perl $Script --cmd query 
                    --query "select count(*) from imgs where url = ? " 
                    --param URL
    } . "\n";
    exit 0;

    return $self;
}

sub _ok {
    my ($self) = @_;

	return @{$self->{ok}};
}

sub _fail {
    my ($self) = @_;

	return @{$self->{fail}};
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

sub cmd_load_file {
    my ($self) = @_;

    $self->load_file;

    return $self;
}

sub load_file {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($file, $file_bn, $sec, $root);

    $root = $self->{root};

    # objects
    my ($prj);

    $file = $self->_opt_($ref,'file');
    $sec  = $self->_opt_($ref,'sec');

    my $atend = sub { $self->info_ok_fail };

    $prj = $self->{prj};
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

    my $proj = $self->{proj};

    $self->debug(qq{Reading:\n\t$file_bn});
###read_file @lines
    my @lines = read_file $file;

    my %n = (
        file     => $file,
        sec      => $sec,
        proj     => $proj,
        root     => $root,
        prj      => $prj,
        gi       => $self,
        dbh      => $self->{dbh},
        img_root => $self->{img_root},
    );
    my $ftc = Plg::Projs::GetImg::Fetcher->new(%n);
    
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

    $self
        ->run_cmd;

    return $self;
}

1;

=head2 SEE ALSO

    see also:
        Plg::Projs::Build::Maker
            cmd_insert_pwg
                cnv_img_begin
=cut

1;
 

