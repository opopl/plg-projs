
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
        warn     => 1,
        user     => 'apopl',
        pwd      => 'root',
        dbfile   => 'piwigo',
        driver   => 'mysql',
        pwg_root => $ENV{PIWIGO},
    };

    $h->{pwg_root_unix} = $h->{pwg_root};
    $h->{pwg_root_unix} =~ s/\\/\//g;
        
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


sub _tex_pic_opts {
    my ($self, $ref) = @_;

    my $width = $ref->{width};

    sprintf(q{width=%s\textwidth},$width); 
};

sub _tex_include_graphics {
    my ($self, $ref) = @_;

    my $w        = $ref->{width};
    my $rel_path = $ref->{rel_path};

    my $pic_opts = $self->_tex_pic_opts({ width => $w });

    my @tex;

    push @tex,
        sprintf(q{\def\picpath{\pwgroot/%s}},$rel_path),
        sprintf(q{\includegraphics[%s]{\picpath}}, $pic_opts ),
        ;

    return @tex;
}

sub _img_include_graphics {
    my ($self, $ref) = @_;

    my $w = $ref->{width};

    my $align = $ref->{align} || '';

    my @tex;

    my @tags = @{ $ref->{tags} || [] };

    my $rel_path = $self->_img_rel_path({ tags => \@tags });

    unless ($rel_path) {
        warn 'rel_path undefined for tags: ' . join(" ",@tags) . "\n";
        return @tex;
    }

    foreach($align) {
        /^center$/ && do { 
            push @tex, q{\centering};
        };
    }

    push @tex,
        $self->_tex_include_graphics({ 
             width    => $w,
             rel_path => $rel_path })
        ;

    return @tex;   
}

sub _img_rel_path {
    my ($self, $ref) = @_;

    my @img = $self->_img_by_tags({ tags => $ref->{tags} });
    my $first = shift @img;

    my $rel_path = $first->{rel_path};

    return $rel_path;
}


sub _img_by_tags {
    my ($self, $ref) = @_;
    
    my @tags = @{ $ref->{tags} || [] };

    local @ARGV = qw( -c img_by_tags );
    push @ARGV, 
        qw( -t ), join("," => @tags);

    $self->run;

    my @img = @{$self->{img} || []};

    return @img;
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
        warn   => $self->_sub_db_warn,
        user   => $self->{user},
        pwd    => $self->{pwd},
        dbfile => $self->{dbfile},
        driver => $self->{driver},
        attr => {
            mysql_enable_utf8 => 1,
        }
    });

    return $self;
}

sub ct_collected {
    my ($self) = @_;

    my $q = '';

    my $dbh = $self->{dbh};
    unless ($dbh) {
        if ($self->{warn}) {
            warn "ct_collected: NO DBH!" . "\n" ;
        }
        return $self;
    }
    
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
        warn => $self->_sub_db_warn,
        q    => $q,
        dbh  => $dbh,
    });

    return $self;
}

sub _sub_db_warn {
    my ($self) = @_;

    $self->{warn} ? sub { warn $_ for(@_) } : sub{};

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

    unless ($dbh) {
        warn "img_by_tags: NO DBH!" . "\n";
        return $self;
    }

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
        warn => $self->_sub_db_warn,
        dbh  => $dbh,
        q    => qq{ SELECT DISTINCT path, comment FROM collected $cond },
        p    => [],
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

        my $full_path = catfile($self->{pwg_root},$path);
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
 

