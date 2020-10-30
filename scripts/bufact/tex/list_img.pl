#!/usr/bin/env perl 
#
package L;

use strict;
use warnings;
use utf8;

use File::Spec::Functions qw(catfile);
use File::Path qw(mkpath);

use Base::DB qw( 
    dbi_connect 
    dbh_do
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

    $self
        ->db_drop
        ->db_create
        ;

    
    $self;
}

sub db_drop {
    my ($self) = @_;

    dbh_do({
        dbh    => $self->{dbh},
        q      => $self->{q}->{drop},
    });
    
    $self;
}

sub db_create {
    my ($self) = @_;

    my $q = $self->{q}->{create};
    dbh_do({
        dbh    => $self->{dbh},
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
                num INTEGER,
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
        ;
    
    my $file = shift @ARGV;
    my $h = {
        file  => $file,
    };

    hash_inject($self, $h);
    return $self;
}

sub load_file {
    my ($self) = @_;

    my @lines = read_file $self->{file};
    print Dumper(\@lines) . "\n";

    my ($is_img, $is_cmt);
    while (@lines) {
        local $_ = shift @lines;
        chomp;
    
        next if /^\s*%/;

        m/^\s*\\ifcmt\b/g && do { $is_cmt=1; next; };
        m/^\s*\\fi\b/g && do { $is_cmt=0 if $is_cmt; next; };

        print $_ . "\n";
        next unless $is_cmt;
    
        m/^\s*img_begin/ && do { $is_img = 1; next; };
    
        m/^\s*img_end/ && do { 
            $is_img = 0; 
        };

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

