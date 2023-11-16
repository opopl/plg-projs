
package Plg::Projs::Prj::Builder::Web;

use strict;
use warnings;
use utf8;

use FindBin qw($Bin $Script);

BEGIN {
    $ENV{DANCER_PUBLIC} = $Bin .'/public';
}

use Dancer2;

use File::Spec::Functions qw(catfile);

use Data::Dumper qw(Dumper);
use Cwd;

#use Dancer2;
use JSON::XS ();
use Image::Info qw(
    image_info
    image_type
);
use Image::ExifTool qw(ImageInfo);
use Text::Template;

use Plg::Projs::Prj::Builder::Web::Routes;

use Plg::Projs::Template qw(
    tmpl_render
    $tm_dir
    $tm_file_page
);

set 'logger'       => 'console';
set 'log'          => 'debug';
set 'static_handler' => 1;
#set public => path( Cwd::cwd(), 'public' );

#set serializer => 'JSON';

my $jsn = JSON::XS->new->utf8->pretty->allow_nonref;

sub act_web {
    my ($bld) = @_;

    #print Dumper($ENV{DANCER_PUBLIC}) . "\n";

    my $imgman = $bld->{imgman};
    my $img_root = $imgman->{img_root};
    $DB::single = 1;

### GET /
    get '/' => sub {
        #redirect '/act/img/html';
        redirect '/prj/sec/html';
    };

### GET /img/raw/:inum
    #get '/img/raw/:inum' => $routes->jsonImgRawInum();

    get '/img/raw/:inum' => sub {
        my $inum = route_parameters->get('inum');

        my $img_db = $imgman->_db_img_one({
            where => { inum => $inum },
            fields => [qw(*)],
        });
        my $img = $img_db->{img};
        my $img_file = catfile($img_root, $img);
        if (-f $img_file) {
            my $if = image_info($img_file);
            my $ct = sprintf($if->{file_media_type});
            response->content_type($ct) if $ct;
            open( my $fh, $img_file ) || die "Can't Open $img_file\n";
            binmode($fh);
            my $buffer = "";
            my $out = "";
            while (read($fh, $buffer, 10240)) {
                $out .= $buffer;
            }
            return $out;
        }
    };

###GET /img/data/:inum
    get '/img/data/:inum' => sub {
        my $inum = route_parameters->get('inum');

        my $img_db = $imgman->_db_img_one({
            where => { inum => $inum },
            fields => [qw(*)],
        });
        response->content_type('application/json');
        $jsn->encode($img_db);
    };

###GET /act/:act
    get '/act/:act/html' => sub {
        my $act = route_parameters->get('act');
        my $sub = sprintf(q{act_%s},$act);
        my $ref = {};
        $bld->$sub($ref) if $bld->can($sub);

        print Dumper($bld->can($sub)) . "\n";

        response->content_type('text/html');

        $ref->{res} // 'err';
    };

###GET /prj/sec/html
    get '/prj/sec/html' => sub {
        my $sec  = query_parameters->get('sec');
        my $proj = query_parameters->get('proj');

        my $data = {
            sec => $sec,
            proj => $proj,
            bld => \$bld,
            jsn => \$jsn,
        };

        tmpl_render('sec.phtml',{ data => $data });
    };

    dance;

    return $bld;
}


1;


