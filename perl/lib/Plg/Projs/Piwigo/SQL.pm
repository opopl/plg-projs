
package Plg::Projs::Piwigo::SQL;

use strict;
use warnings;

use FindBin qw($Bin $Script);
use Getopt::Long qw(GetOptions);

use Data::Dumper qw(Dumper);
use File::Spec::Functions qw(catfile);

use utf8; 
use open qw(:utf8 :std);
use Encode;

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
    my ($self, $ref) = @_;

    my $cmd;
    unless (keys %$ref) {
        $self->get_opt;
        $cmd = $self->{opt}->{cmd};
    }else{
        $cmd = $ref->{cmd} || '';
    }

    if ($cmd) {
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
        user              => $self->{user},
        pwd               => $self->{pwd},
        dbfile            => $self->{dbfile},
        driver            => $self->{driver},
        attr => {
            mysql_enable_utf8 => 1,
        }
    });

    return $self;
}

sub ct_collected {
    my ($self) = @_;

    my $q = '';
    
    $q .= qq{
        SET CHARACTER SET utf8;
        SET NAMES utf8;
    };

    $q .= qq{
        DROP TABLE IF EXISTS collected;

        CREATE TABLE collected SELECT 
          piwigo_images.id,
          piwigo_images.file,
          piwigo_images.path,
          piwigo_images.comment,
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

sub cmd_ct_collected {
    my ($self) = @_;

    $self
        ->ct_collected
        ;

    return $self;
}

sub cmd_img_by_tags {
    my ($self, $tags_s) = @_;

    $self->ct_collected;

    $tags_s ||= $self->{opt}->{tags};
    $tags_s ||= '';

    my @tags_a = split("," => $tags_s);

    my @cond;
   
    if (@tags_a) {
        push @cond,
             qq{ WHERE tag IN ( },
             join( "," => map { "'" . $_ . "'" } @tags_a ),
             qq{)},
             ;
    } 

    my $q = qq{
        SELECT 
            path, comment, tag
        FROM 
            collected
    } 
        . join(" ",@cond)
        . qq{ HAVING COUNT(*) = } . scalar @tags_a 
        ;

    #my $res = dbh_selectall_arrayref({
        #dbh => $self->{dbh},
        #q   => $q,
        #p   => [],
    #});

    my ($rows, $cols) = dbh_select({
        dbh => $self->{dbh},
        q   => $q,
        p   => [],
    });
print Dumper($rows) . "\n";

    my $first = shift @$rows;
    
    my $path = $first->{path};
    my $comment = $first->{comment};

    my $full_path = catfile($self->{piwigo},$path);

    if ($^O eq 'MSWin32') {
        $full_path =~ s/\\/\//g;
    }

    if (-e $full_path) {
	    $self->{img} = {
	        path       => $full_path,
			#comment    => decode('utf8',$comment),
	        comment    => $comment,
	    };
    }

    $self;
}

1;
 

