
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
                perl $Script -p PROJ -r ROOT --debug
            RESET DATABASE, REMOVE IMAGE FILES:
                perl $Script --reset
    } . "\n";
    exit 0;

    return $self;
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
            print Dumper({ url => $url }) . "\n";
    
            my $url_s = $^O eq 'MSWin32' ? qq{"$url"} : qq{$url};
    
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

sub load_file {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($file, $file_bn, $sec, $root);

    $root = $self->{root};

    # objects
    my ($prj);

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

    my $img_root = $self->{img_root};

    $self->debug(qq{Reading:\n\t$file_bn});
###read_file @lines
    my @lines = read_file $file;

    # flags
    my ($is_img, $is_cmt, $url);

    my @data;
    my $d = {};

    chdir $img_root;

###LINES
    LINES: while (@lines) {
        local $_ = shift @lines;
        chomp;

        next if /^\s*%/;

        m/^\s*\\ifcmt\b/g && do { $is_cmt = 1; next; };
###\fi
        m/^\s*\\fi\b/g && do { 
            $is_cmt = 0 if $is_cmt; 

            next unless @data;

            while(@data){
                $d = shift @data;

                $url = $d->{url};
                next unless $url;

                my $img_db = dbh_select_fetchone({
                    q => q{ SELECT img FROM imgs WHERE url = ? },
                    p => [ $url ],
                });

                if($img_db) {
                    my $img_db_file = catfile($img_root,$img_db);
                    if ( -e $img_db_file ) {
                        next;
                    }
                }

                my $ref = {
                    q => q{ SELECT MAX(inum) FROM imgs },
                };
                my $max  = dbh_select_fetchone($ref);
                my $inum = ($max) ? ($max + 1) : 1;
    
                my ($scheme, $auth, $path, $query, $frag) = uri_split($url);
                my $bname = basename($path);
                my ($ext) = ($bname =~ m/\.(\w+)$/);
                $ext ||= 'jpg';
                $ext = lc $ext;
    
                my $img      = sprintf(q{%s.%s},$inum,$ext);
                my $img_file = catfile($img_root,$img);

                my @subs = $self->_subs_url({ 
                    url      => $url,
                    img_file => $img_file,
                    sec      => $sec,
                });

                while(! -e $img_file){
                    my $s = shift @subs;
                    my $ss = $s->();
                }

                next unless(-e $img_file);

                my $idt = which 'identify';
                if ($idt) {
                    # body...
                }
            
                dbh_insert_hash({
                    t => 'imgs',
                    i => q{ INSERT OR REPLACE },
                    h => {
                        inum    => $inum,
                        url     => $url,
                        proj    => $self->{proj},
                        rootid  => $self->{rootid},
                        sec     => $sec,
                        img     => $img,
                        ext     => $ext,
                        caption => $d->{caption} || '',
                        tags    => $d->{tags} || '',
                        name    => $d->{name} || '',
                    },
                });
            }

        };
###\fi_end

        m/^\s*img_begin\b/g && do { $is_img = 1; next; };

###img_end
        m/^\s*img_end\b/g && do { 
            $is_img = 0 if $is_img; 

            push @data, $d if keys %$d;
            $d = {};

            next; 
        };

        while(1){
###if_is_img
            if ($is_img) {
###match_url
                m/^\s*url\s+(.*)$/g && do { 
                    push @data, $d if keys %$d;

                    $d = { url => $1 };
                    $url = $1;
                    last;
                };

                m/^\s*(\w+)\s+(.*)$/g && do { 
                   $d->{$1} = $2; 
                };

                last;
            }
    
            m/^\s*pic\s+(.*)$/g && do { 
                $url = $1;
                push @data, { url => $url };
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
 
