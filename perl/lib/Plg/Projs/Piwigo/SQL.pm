
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

    my $dbh = $self->{dbh};

    $self->ct_collected;

    $tags_s ||= $self->{opt}->{tags};
    $tags_s ||= '';

    my @tags_in = split("," => $tags_s);
    my %tags_in = map { $_ => 1 } @tags_in;

    my (@cond, $cond);
    my ($rows, $cols);
   
    if (@tags_in) {
        push @cond,
             qq{ WHERE tag IN ( },
             join( "," => map { "'" . $_ . "'" } @tags_in ),
             qq{)},
             ;

        $cond = join(" ",@cond);
    } 

    ($rows,$cols) = dbh_select({
        dbh => $dbh,
        q   => qq{ SELECT DISTINCT path, comment FROM collected $cond },
        p   => [],
    });

    my @img;
    my %done;

    foreach my $row (@$rows) {
        my $path    = $row->{path};
        my $comment = $row->{comment};

        my @tags_r = dbh_select_as_list({
            dbh => $dbh,
            q   => qq{ SELECT tag FROM collected WHERE path = ? },
            p   => [$path],
        });
        my $tgs = join(" ",sort { length($a) <=> length($b)} @tags_r);
        my %tags_r = map { $_ => 1 } @tags_r;

        my $in=1;
        for(@tags_in){
            unless($tags_r{$_}) {
                $in=0; last;
            }
        }
        next unless $in;

        my $full_path = catfile($self->{piwigo},$path);
        next if $done{$full_path};
    
        if ($^O eq 'MSWin32') {
            $full_path =~ s/\\/\//g;
        }
        if (-e $full_path) {
            push @img, {  
                full_path => $full_path,
                rel_path  => $path,
                tgs       => $tgs,
                #comment  => decode('utf8',$comment),
                comment   => $comment,
            };
            $done{$full_path}=1;
        }
    }

    $self->{img} = [@img];
    #print Dumper([@img]) . "\n";

    $self;
}

1;
 

