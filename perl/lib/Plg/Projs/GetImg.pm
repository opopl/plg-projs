
package Plg::Projs::GetImg;

use strict;
use warnings;
use utf8;

use Plg::Projs::Prj;

use File::Spec::Functions qw(catfile);
use File::Path qw( mkpath rmtree );

use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use File::Which qw(which);  

use URI::Split qw(uri_split);

use LWP::Simple qw(getstore);
use LWP::UserAgent;
use Getopt::Long qw(GetOptions);

use base qw(
    Base::Opt
    Base::Logging
);

use Base::DB qw( 
    dbi_connect 
    dbh_do
    dbh_select_fetchone
    dbh_insert_hash
);

use Base::Arg qw( 
    hash_inject 
);

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
        attr   => {},
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
	if ($self->{reset}) {
		rmtree $img_root if -d $img_root;
	}
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
                inum INTEGER,
                tags TEXT,
                rootid TEXT,
                proj TEXT,
                sec TEXT,
                img TEXT,
                caption TEXT,
				name TEXT,
				ext TEXT
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

    $self
        ->get_opt
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
        "cmd|c=s",
        "reset",
        "debug|d",
    );
    
    unless( @ARGV ){ 
        $self->print_help;
        exit 0;
    }else{
        GetOptions(\%opt,@optstr);
        $self->{opt} = \%opt;
    }

    foreach my $k (keys %opt) {
        $self->{$k} = $opt{$k};
    }

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
            RESET DATABASE, REMOVE IMAGE FILES:
                perl $Script --reset
    } . "\n";
    exit 0;

    return $self;
}

sub load_file {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($file, $file_bn, $sec, $root);

    $root = $self->{root};

    # objects
    my ($lwp, $prj);

    $file = $self->_opt_($ref,'file');
    $sec  = $self->_opt_($ref,'sec');

    $prj = $self->{prj};
    unless ($file) {
        foreach($prj->_files){

            my $file = catfile($root,$_->{file});
            my $sec  = $_->{sec};

            $self->load_file({
                file => $file,
                sec  => $sec,
            });
        }
        return $self;
    }
    $file_bn = basename($file);

    $lwp  = $self->{lwp};

    my $img_root = $self->{img_root};

    $self->debug(qq{Reading:\n\t$file_bn});
###@lines
    my @lines = read_file $file;

    # flags
    my ($is_img, $is_cmt);

    my (%d);
    my @keys = qw( url caption tags name );

    chdir $img_root;

    LINES: while (@lines) {
        local $_ = shift @lines;
        chomp;

        next if /^\s*%/;

        m/^\s*\\ifcmt\b/g && do { $is_cmt = 1; next; };
        m/^\s*\\fi\b/g && do { 
            $is_cmt = 0 if $is_cmt; 

            next unless $d{url};

            my $ref = {
                q => q{ SELECT MAX(inum) FROM imgs },
            };
            my $max  = dbh_select_fetchone($ref);
            my $inum = ($max) ? ($max + 1) : 1;

            my ($scheme, $auth, $path, $query, $frag) = uri_split($d{url});
            my $bname = basename($path);
            my ($ext) = ($bname =~ m/\.(\w+)$/);
            $ext ||= 'jpg';
			$ext = lc $ext;

            my $img      = sprintf(q{%s.%s},$inum,$ext);
            my $img_file = catfile($img_root,$img);

            my ($url, $caption, $tags, $name) = @d{@keys};
            %d = ();

            my $img_db = dbh_select_fetchone({
                q => q{ SELECT img FROM imgs WHERE url = ? },
                p => [ $url ],
            });

            if($img_db && -e catfile($img_root,$img_db)) {
                next;
            }

            my $curl = which 'curl';
            if ($curl) {
                my $cmd = qq{ $curl -o "$img_file" '$url' };
                my $x = qx{ $cmd 2>&1 };
                $self->debug(["Command:", $x]);
            } else {
                my $res = $lwp->mirror($url,$img_file);
                unless ($res->is_success) {
                    print "LWP Error: $url " . "\n";
                    print $res->status_line . "\n";
                    next;
                }
            }
            
            dbh_insert_hash({
                t => 'imgs',
                i => q{ INSERT OR REPLACE },
                h => {
                    inum    => $inum,
                    url     => $url,
                    caption => $caption || '',
                    proj    => $self->{proj},
                    rootid  => $self->{rootid},
                    sec     => $sec,
                    img     => $img,
                    tags    => $tags,
                    ext     => $ext,
                    name    => $name,
                },
            });

        };

        m/^\s*img_begin\b/g && do { $is_img=1; next; };
        m/^\s*img_end\b/g && do { $is_img=0 if $is_img; next; };

        while(1){
            if ($is_img) {
                for my $k (@keys){
                    m/^\s*$k\s+(.*)$/g && do { 
                        $d{$k} = $1; 
                    };
                }
                last;
            }
    
            m/^\s*pic\s+(.*)$/g && do { 
                $d{url} = $1;
                last; 
            };

            last;
        }

    }

    return $self;
}

sub run {
    my ($self) = @_;

    $self
        ->load_file
        ;

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
 

