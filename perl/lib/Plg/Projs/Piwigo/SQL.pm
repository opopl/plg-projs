
package Plg::Projs::Piwigo::SQL;

use strict;
use warnings;

use FindBin qw($Bin $Script);
use Getopt::Long qw(GetOptions);

use Data::Dumper qw(Dumper);
use File::Spec::Functions qw(catfile);

use Base::DB qw(
    dbh_insert_hash
    dbh_select
    dbh_select_first
    dbh_select_as_list
    dbh_select_fetchone
    dbh_do
    dbh_list_tables
    dbh_selectall_arrayref
    dbh_sth_exec
    dbh_update_hash
    dbi_connect
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

    my $h = {
        user   => 'apopl',
        pwd    => 'root',
        dbfile => 'piwigo',
        driver => 'mysql',
        piwigo => $ENV{PIWIGO},
    };
        
    my @k = keys %$h;

    for(@k){ $self->{$_} = $h->{$_} unless defined $self->{$_}; }

    $self
        ->init_db
        ->ct_collected
        ;

    return $self;
}

      
sub get_opt {
    my ($self) = @_;

    my(%opt, @optstr, $cmdline);
    
    Getopt::Long::Configure(qw(bundling no_getopt_compat no_auto_abbrev no_ignore_case_always));
    
    @optstr = ( 
        "tags|t=s",
        "cmd|c=s",
    );
    
    unless( @ARGV ){ 
        $self->dhelp;
        exit 0;
    }else{
        $cmdline = join(' ',@ARGV);
        GetOptions(\%opt,@optstr);
        $self->{opt} = \%opt;
    }

    return $self;   
}

sub dhelp {
    my ($self) = @_;

    my $s = qq{

    USAGE
        $Script OPTIONS
    OPTIONS

    EXAMPLES
        perl $Script -c img_by_tags

        perl $Script -c ct_files - create table collected + files

    };

    print $s . "\n";
    exit 0;

    return $self;   
}

sub run {
    my ($self) = @_;

    $self->get_opt;

    if ( my $cmd = $self->{opt}->{cmd} ) {
        my $sub = 'cmd_' . $cmd;
        if ($self->can($sub)){
            $self->$sub;
        }
    }

    return $self;
}

sub init_db {
    my ($self) = @_;

    $self->{dbh} = dbi_connect({
        user   => $self->{user},
        pwd    => $self->{pwd},
        dbfile => $self->{dbfile},
        driver => $self->{driver},
    });

    return $self;
}

sub ct_collected {
    my ($self) = @_;

    my $q = qq{
        DROP TABLE IF EXISTS collected;

        CREATE TABLE collected SELECT 
          piwigo_images.id,
          piwigo_images.file,
          piwigo_images.path,
          piwigo_tags.name as tag,
          piwigo_image_tag.tag_id
        FROM ( 
           ( piwigo_images 
               INNER JOIN 
                    piwigo_image_tag 
               ON 
                    piwigo_image_tag.image_id = piwigo_images.id 
           )
                INNER JOIN 
                    piwigo_tags 
                ON 
                    piwigo_image_tag.tag_id = piwigo_tags.id
        )
    };

    dbh_do({
        q   => $q,
        dbh => $self->{dbh},
    });

    return $self;
}

sub ct_files {
    my ($self) = @_;

    my $q = qq{
        DROP TABLE IF EXISTS files;

        CREATE TABLE files (
            path VARCHAR(255),
            tags TINYTEXT
        ); 
    };

    dbh_do({
        q   => $q,
        dbh => $self->{dbh},
    });



    return $self;
}

sub cmd_ct_files {
    my ($self) = @_;

    $self
        ->ct_collected
        #->ct_files
        ;

    return $self;
}

sub cmd_img_by_tags {
    my ($self, $tags_s) = @_;

    $tags_s ||= $self->{opt}->{tags};
    $tags_s ||= '';

    my @tags_a = split("," => $tags_s);

    my @cond;
   
    if (@tags_a) {
        push @cond,
             qq{ WHERE tag IN ( },
             join( "," => map { "'" . $_ . "'" } @tags_a ),
             qq{)},
             #qq{ HAVING COUNT(*) = } . scalar @tags_a
             ;
    } 

    my $q = qq{
        SELECT 
            path, tag
        FROM 
            collected
    } 
        . join(" ",@cond)
        . qq{ HAVING COUNT(*) = } . scalar @tags_a 
        ;

    my $res = dbh_selectall_arrayref({
        dbh => $self->{dbh},
        q   => $q,
        p   => [],
    });
    my $first = shift @{$res->[0]->{rows} || []};

    my $path = shift @$first;

    if ($^O eq 'MSWin32') {
        $path =~ s/\//\\/g;
    }

    my $full_path = catfile($self->{piwigo},$path);

    if (-e $full_path) {
        print 'OK' . "\n";
    }

    $self;
}

1;
 

