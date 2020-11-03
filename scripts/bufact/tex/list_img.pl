#!/usr/bin/env perl 
#
package L;

use strict;
use warnings;
use utf8;

use File::Spec::Functions qw(catfile);
use File::Path qw(mkpath);

use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);

use LWP::Simple qw(getstore);
use LWP::UserAgent;
#use Digest::MD5  qw( md5_hex );
#use Digest::MD5::File qw( file_md5_hex );
#use File::Fetch;

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

sub init_db {
    my ($self) = @_;

    my $img_root = $ENV{IMG_ROOT} // catfile($ENV{HOME},qw(img_root));
    mkpath $img_root unless -d $img_root;
    
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

    $self
        ->db_drop
        ->db_create
        ;

    
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
                url TEXT,
                inum INTEGER,
                tags TEXT,
                rootid TEXT,
                proj TEXT,
                sec TEXT,
                caption TEXT
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
        ->init_q
        ->init_db
        ->init_lwp
        ;

    unless (@ARGV) {
        $self->print_help;
        exit 0;
    }
    
    my $file = shift @ARGV;
    my $h = {
        file  => $file,
    };

    hash_inject($self, $h);
    return $self;
}

sub print_help {
    my ($self) = @_;

    print qq{
        LOCATION:
            $0
        USAGE:
             perl $Script FILE 
    } . "\n";
    exit 0;

    return $self;
}

sub load_file {
    my ($self) = @_;

    my $file = $self->{file};
    my $lwp  = $self->{lwp};

    my ($proj, $sec) = ( basename($file)  =~ m/^(\w+)\.(.*)\.tex$/g );

    my @lines = read_file $file;

    my ($is_img, $is_cmt);

    my (%d);
    my @keys = qw(url caption);

    LINES: while (@lines) {
        local $_ = shift @lines;
        chomp;

        next if /^\s*%/;

        m/^\s*\\ifcmt\b/g && do { $is_cmt=1; next; };
        m/^\s*\\fi\b/g && do { 
            $is_cmt = 0 if $is_cmt; 

            next unless $d{url};

            my $ref = {
                q => q{SELECT MAX(inum) FROM imgs},
            };
            my $max = dbh_select_fetchone($ref);
            my $inum = ($max) ? ($max + 1) : 1;
            
            dbh_insert_hash({
                t => 'imgs',
                i => q{ INSERT OR REPLACE },
                h => {
                    inum    => $inum,
                    url     => $d{url},
                    caption => $d{caption} || '',
                    proj    => $proj,
                    sec     => $sec,
                },
            });

            %d=();
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


package main;

L->new->run;




=head2 SEE ALSO

    see also:
        Plg::Projs::Build::Maker
            cmd_insert_pwg
                cnv_img_begin
=cut

