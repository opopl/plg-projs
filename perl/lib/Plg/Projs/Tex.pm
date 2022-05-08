
package Plg::Projs::Tex;

use strict;
use warnings;
use utf8;

use Plg::Projs::Build::Maker::Jnd::Processor;

use Data::Dumper qw(Dumper);
use Base::String qw(
    str_split
);

use String::Util qw(trim);
use Text::Wrap ();

use JSON::XS;
use Regexp::Common qw(URI);

binmode STDOUT,':encoding(utf8)';

use Exporter ();
use base qw(Exporter);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Text::Sprintf::Named qw(named_sprintf);

@ISA     = qw(Exporter);
@EXPORT  = qw( );
$VERSION = '0.01';

###our
our($l_start,$l_end);

our(@lines,@new);

# JSON-decoded input data
our($data_input);

our(@split,@before,@after,@center);

our ($s, $s_full);

my @ex_vars_scalar=qw(
);
my @ex_vars_hash=qw(
    %fbicons
);
my @ex_vars_array=qw(
);

%EXPORT_TAGS = (
    'funcs' => [qw( 
        q2quotes
        texify
        texify_ref
    )],
    'vars'  => [ @ex_vars_scalar,@ex_vars_array,@ex_vars_hash ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );

###flag
our %flag = (
  head => undef,
  cmt => undef,
  push => undef,
  fbauth => undef,
);

###secs
our $secs = {
  down => [
      { paragraph => 'subparagraph' },
      { subsubsection => 'paragraph' },
      { subsection => 'subsubsection' },
      { section => 'subsection' },
      { chapter => 'section' },
      { part => 'chapter' },
  ],
  up => [
      { chapter => 'part' },
      { section => 'chapter' },
      { subsection => 'section' },
      { subsubsection => 'subsection' },
      { paragraph => 'subsubsection' },
      { subparagraph => 'paragraph' },
  ]
};

###fbicons_weak
our %fbicons_weak = (
  '☀️'  => 'sun',
  '☝️'  => 'index.pointing.up',
  '☎️' => 'telephone',
  '❄️' => 'snowflake',
  '♥️'  => 'heart.suit',
  '❗️' => 'exclamation.mark',
  '‼️'  => 'exclamation.mark.double',
  '⚡️' => 'lightning',
  '✔️'  => 'check.mark',
  '🇺🇦' => 'flag.ukraina',
  '🇭🇺' => 'flag.vengria',
  '🇪🇺' => 'flag.eu',
  '❣️'  => 'heart.exclamation',
  '✌️'  => 'hand.victory',
  '❤️'  => 'heart',
  '❤️'  => 'heart.red',
);

###fbicons_arrows
our %fbicons_arrows = (
  '9️⃣'  => 'digit.nine.keycap',
  '0️⃣'  => 'digit.zero.keycap',
  '↕️'  => 'arrow.updown',
  '⤵️'  => 'right.arrow.curving.down',
  '🔝' => 'top.arrow',
  '⬇️'  => 'arrow.pointing.down',
);

###fbicons_heart
our %fbicons_heart = (
  '🤍' => 'heart.white',
  '💚' => 'heart.green',
  '💟' => 'heart.decoration',
  '💔' => 'heart.broken',
  '💖' => 'heart.sparkling',
  '💗' => 'heart.growing',
  '🧡' => 'heart.orange',
  '💙' => 'heart.blue',
  '💜' => 'heart.purple',
  '🖤' => 'heart.black',
  '💛' => 'heart.yellow',
  '💕' => 'hearts.two',
  '💓' => 'heart.beating',
  '🤎' => 'heart.brown',
  '💝' => 'heart.with.ribbon',
  '💞' => 'hearts.revolving',
  '💘' => 'heart.with.arrow',
);

###fbicons_all
###all
our %fbicons_all = (
  '🛡' => 'shield',
  '🚨' => 'police.car.light',
  '👐' => 'open.hands', 
  '📢' => 'loudspeaker',
  '🧠' => 'brain',
  '🩸' => 'drop.blood',
  '💵' => 'dollar.banknote',
  '🔻' => 'red.triangle.pointed.down',
  '🚫' => 'prohibited',
  '🩹' => 'adhesive.bandage',
  '📘' => 'blue.book',
  '🏫' => 'school',
  '⚔️'  => 'crossed.swords',
  '🎖' => 'military.medal',
  '🔱' => 'trident',
  '💀' => 'skull',
  '📷' => 'camera',
  '🐱' => 'cat.face',
  '🏠' => 'house',
  '🎙' => 'studio.microphone',
  '⭐️' => 'star',
  '👸' => 'princess',
  '🚴' => 'person.biking',
  '🌼' => 'blossom',
  '👨' => 'man',
  '🧚' => 'fairy',
  '📈' => 'chart.increasing',
  '💬' => 'speech.baloon',
  '⏰' => 'alarm.clock',
  '⛔️' => 'no.entry',
  '🌠' => 'shooting.star',
  '🎊' => 'confetti.ball',
  '💶' => 'euro.banknote',
  '🐜' => 'ant',
  '👗' => 'dress',
  '🎀' => 'ribbon',
  '🛑' => 'stop.sign',
  '🎼' => 'musical.score',
  '🌲' => 'evergreen.tree',
  '🪁' => 'kite',
  '🌦' => 'sun.behind.rain.cloud',
  '🍄' => 'mushroom',
  '🤳' => 'selfie',
  '🌌' => 'milky.way',
  '🖐' => 'hand.fingers.splayed',
  '🐽' => 'pig.nose',
  '🐶' => 'dog.face',
  '🐦' => 'bird',
  '🚩' => 'flag.triangular',
  '🚘' => 'oncoming.automobile',
  '🎨' => 'artist.palette',
  '🐏' => 'ram',
  '👂' => 'ear',
  '🍸' => 'cocktail.glass',
  '💒' => 'wedding',
  '🕌' => 'mosque',
  '🦄' => 'unicorn',
  '🐞' => 'lady.beetle',
  '🐥' => 'baby.chick.front.facing',
  '💑' => 'couple.with.heart',
  '🤙' => 'call.me.hand',
  '🤟' => 'love.you.gesture',
  '🐎' => 'horse',
  '⚽' => 'soccer.ball',
  '🥮' => 'moon.cake',
  '🧩' => 'puzzle.piece',
  '🌾' => 'sheaf.of.rice',
  '🥞' => 'pancakes',
  '🦍' => 'gorilla',
  '♿' => 'wheelchair',
  '🦠' => 'microbe',
  '🧄' => 'garlic',
  '🌶️' => 'hot.pepper',
  '🗓' => 'calendar.spiral',
  '📱' => 'mobile.phone',
  '📧' => 'email',
  '🗃' => 'card.file.box',
  '📒' => 'ledger',
  '📝' => 'memo',
  '👩' => 'woman',
  '📞' => 'telephone.receiver',
  '🗺' => 'world.map',
  '📇' => 'card.index',
  '👤' => 'shadow',
  '🚚' => 'delivery.truck',
  '📓' => 'notebook',
  '🐈' => 'cat',
  '🆘' => 'sos.button',
  '👁' => 'glaz',
  '🎪' => 'circus.tent',
  '🥃' => 'tumbler.glass',
  '👆' => 'backhand.index.pointing.up',
  '🤞' => 'crossed.fingers',
  '🦆' => 'duck',
  '🦧' => 'orangutan',
  '🐀' => 'rat',
  '🤜' => 'fist.right.facing',
  '🤛' => 'fist.left.facing',
  '💏' => 'kiss',
  '🌈' => 'rainbow',
  '🌐' => 'globe.with.meridians',
  '☕' => 'hot.beverage',
  '🔎' => 'glass.magnifying.right.pointing',
  '🔆' => 'bright.button',
  '📚' => 'books',
  '⛄' => 'snowman.without.snow',
  '🎅' => 'santa.claus',
  '🥂' => 'clinking.glasses',
  '🍷' => 'wine.glass',
  '🌱' => 'seedling',
  '🎈' => 'balloon',
  '🎻' => 'violin',
  '🏔' => 'mountain.snow.capped',
  '🌟' => 'glowing.star',
  '🎁' => 'gift.wrapped',
  '🌊' => 'water.wave',
  '🎭' => 'performing.arts',
  '🥀' => 'wilted.flower',
  '🎄' => 'christmas.tree',
  '🐮' => 'cow.face',
  '🚲' => 'bicycle',
  '🎩' => 'top.hat',
  '🍂' => 'fallen.leaf',
  '🔺' => 'triangle.red.up',
  '🕺' => 'man.dancing',
  '💦' => 'sweat.droplets',
  '🚓' => 'police.car',
  '🐓' => 'rooster',
  '🐍' => 'snake',
  '🌎' => 'globe.showing.americas',
  '🤲' => 'palms.up.together',
  '💣' => 'bomb',
  '🖋' => 'fountain.pen',
  '📃' => 'page.with.curl',
  '🐸' => 'frog',
  '👹' => 'ogre',
  '🔴' => 'circle.red',
  '🐕' => 'dog',
  '🐷' => 'pig.face',
  '🍿' => 'popcorn',
  '🗑' => 'wastebasket',
  '☠️'  => 'skull.crossbones',
  '🎮' => 'video.game',
  '🦸' => 'superhero',
  '🦏' => 'nosorog',
  '📌' => 'pushpin',
  '💧' => 'droplet',
  '📍' => 'round.pushpin',
  '🍒' => 'cherries',
  '👊' => 'fist.oncoming',
  '🏆' => 'trophy',
  '🥇' => 'medal.first.place',
  '🥊' => 'boxing.glove',
  '🌹' => 'rose',
  '👌' => 'hand.ok',
  '🎯' => 'direct.hit',
  '🙌' => 'hands.raising',
  '💃' => 'woman.dancing',
  '🌻' => 'sunflower',
  '👅' => 'tongue',
  '➕' => 'plus',
  '🌷' => 'tulip',
  '🚗' => 'automobile',
  '🏙️' => 'cityscape',
  '📸' => 'camera.with.flash',
  '🕊' => 'dove',
  '🔥' => 'flame',
  '🙏' => 'hands.pray',
  '👍' => 'thumb.up.yellow',
  '👎' => 'thumb.down.yellow',
  '❤️'  => 'heart',
  '👏' => 'hands.applause.yellow',
  '🎉' => 'party.popper',
  '🏡' => 'house.with.garden',
  '🌸' => 'cherry.blossom',
  '💯' => '100.percent',
  '👉' => 'index.pointing.right',
  '👈' => 'index.pointing.left',
  '💐' => 'bouquet',
  '💭' => 'thought.baloon',
  '🦉' => 'owl',
  '🔔' => 'bell',
  '🤦' => 'man.facepalming',
  '💋' => 'kiss.mark',
  '🤝' => 'hands.shake',
  '💪' => 'biceps.flexed',
  '✊' => 'fist.raised',
  '📖' => 'book.open',
  '🔑' => 'key',
  '🛐' => 'place.of.worship',
  '🕍' => 'synagogue',
  '⛪' => 'church',
  '🕋' => 'kaaba',
  '🎣' => 'fishing',
  '💎' => 'gem',
  '🌀' => 'cyclone',
  '🌞' => 'sun.with.face',
  '🍰' => 'shortcake',
  '🎂' => 'cake.birthday',
  '🍾' => 'bottle.popping.cork',
  '✨' => 'sparkles',
  '🔹' => 'diamond.blue.small',
  '🔸' => 'diamond.orange.small',
  '🙈' =>  'monkey.see.no.evil',
  '🙉' => 'monkey.hear.no.evil',
  '👀' => 'eyes',
  '🤷' => 'shrug',
  '🚀' => 'rocket',
  '📺' => 'television',
  '👋' => 'hand.waving',
  '📵' => 'no.mobile.phones',
  '💩' => 'pile.of.poo',
  '🍁' => 'maple.leaf',
  '🎶' => 'musical.notes',
  '🌅' => 'sunrise',
  '🏃' => 'runner',
  '🕯' => 'candle',
  '👇' => 'pointing.down',
  '🖕' => 'finger.middle',
  '💥' => 'collision',
  '💫' => 'dizzy',
  '🤘' => 'horns',
  '✅' => 'check.mark.white.heavy',
  '💌' => 'love.letter',
  '🍀' => 'clover',
  '😺' => 'cat.grinning',
  '😻' => 'cat.heart.eyes',
  '🙀' => 'cat.weary',
  '😿' => 'cat.crying',
  '🌺' => 'hibiscus',
  '🎬' => 'clapboard',
  '☄️'  => 'comet',
  '👼' => 'baby.angel',
  '📣' => 'megaphone',
  '🌍' => 'globe.europe.afrika',
  '🌏' => 'globe.asia.australia',
  '😹' => 'cat.tears.of.joy',
  '🙊' => 'monkey.speak.no.evil',
  '👮' => 'police.officer',
  '👙' => 'bikini',
  '🎒' => 'backpack',
  '⛵' => 'sailboat',
  '🦋' => 'butterfly',
  '👽' => 'alien',
  '🌿' => 'herb',
  '🐛' => 'bug',
  '🎥' => 'movie.camera',
  '🍓' => 'strawberry',
  '🏴' => 'flag.black',
  '💉' => 'syringe',
  '🍹' => 'tropical.drink',
  '🍨' => 'ice.cream',
  '🗽' => 'statue.of.liberty',
  '🏳' => 'white.flag',
);

###fbicons_person
our %fbicons_person = (
  '💁' => 'person.tipping.hand',
  '👳' => 'person.wearing.turban',
  '🙆' => 'person.gesturing.ok',
  '👰' => 'person.veil',
  '🤵' => 'person.tuxedo',
  '🙋' => 'person.raising.hand',
  '🧑' => 'person',
);

###fbicons_face
our %fbicons_face = (
  '☹️'  => 'face.frowning',
  '😖' => 'face.confounded',
  '😉' => 'wink',
  '😷' => 'face.medical.mask',
  '😑' => 'face.expressionless',
  '🥵' => 'face.hot',
  '😵' => 'face.eyes.crossed.out',
  '😧' => 'face.anguished',
  '🥱' => 'face.yawning',
  '😛' => 'face.tongue',
  '🥶' => 'face.cold',
  '😟' => 'face.worried',
  '🤫' => 'face.shushing',
  '🤭' => 'face.hand.over.mouth',
  '🤢' => 'face.nauseated',
  '😮' => 'face.open.mouth',
  '😗' => 'face.kissing',
  '😓' => 'face.downcast.sweat',
  '🥳' => 'face.partying',
  '🤤' => 'face.drooling',
  '😲' => 'face.astonished',
  '😴' => 'face.sleeping',
  '🤑' => 'face.money.mouth',
  '😤' => 'face.steam.nose',
  '🤪' => 'face.zany',
  '😕' => 'face.confused',
  '🤡' => 'face.clown',
  '😱' => 'face.screaming.in.fear',
  '🥴' => 'face.woozy',
  '😈' => 'face.smiling.horns',
  '👿' => 'face.angry.horns',
  '🥺' => 'face.pleading',
  '😠' => 'face.angry',
  '😝' => 'face.squinting.tongue',
  '😳' => 'face.flushed',
  '😞' => 'face.disappointed',
  '🤨' => 'face.eyebrow.raised',
  '😭' => 'face.crying.loudly',
  '🙂' => 'smile',
  '😡' => 'anger',
  '🙁' => 'frown',
  '😀' => 'grin',
  '😢' => 'cry',

  '🤣' => 'laugh.rolling.floor',
  '😍' => 'heart.eyes',

  '😁' => 'beaming.face.smiling.eyes',
  '🤔' => 'thinking.face',

  '😩' => 'face.weary',
  '😣' => 'face.persevering',
  '😶' => 'face.without.mouth',
  '😬' => 'face.grimacing',
  '🥰' => 'face.smiling.hearts',
  '😘' => 'face.blowing.kiss',
  '😜' => 'face.wink.tongue',
  '🤮' => 'face.womiting',
  '🤗' => 'face.happy.two.hands',
  '😅' => 'face.grinning.sweat',
  '😂' => 'face.tears.of.joy',
  '😃' => 'face.grinning.big.eyes',
  '😎' => 'face.smiling.sunglasses',
  '🌝' => 'face.full.moon',
  '😆' => 'face.grinning.squinting',
  '🤧' => 'face.sneezing',
  '🙃' => 'face.upside.down',
  '😄' => 'face.grinning.smiling.eyes',
  '🙄' => 'face.rolling.eyes',
  '😇' => 'face.smiling.halo',
  '😊' => 'face.smiling.eyes.smiling',
  '😐' => 'face.neutral',
  '😒' => 'face.unamused',
  '🤬' => 'face.symbols.mouth',
  '🤯' => 'face.shoked.head.exploding',
  '😌' => 'face.relieved',
  '☺️'  => 'face.smiling',
  '😏' => 'face.smirking',
  '☻'  => 'face.smiling.black',
  '😥' => 'face.sad.but.relieved',
  '🤕' => 'face.head.bandage',
  '😔' => 'face.pensive',
  '😪' => 'face.sleepy',
  '🤓' => 'face.nerd',
  '🤩' => 'face.eyes.star',
  '🧐' => 'face.monocle',
  '😰' => 'face.anxious.sweat',
  '😚' => 'face.kissing.closed.eyes',
  '😋' => 'face.savoring.food',
  '😯' => 'face.hushed',
);

###fbicons
our %fbicons = ( 
  %fbicons_all, 
  %fbicons_face,
  %fbicons_weak,
  %fbicons_heart,
  %fbicons_person,
  %fbicons_arrows,
);

sub texify_ref {
    my ($ref) = @_;
    $ref ||= {};

    my @keys = qw( ss cmd s_start s_end data_js );

    push @keys, qw( sub );
    #my ($ss,$cmd,$s_start,$s_end,$data_js) = @{$ref}{@keys};
    my @args = @{$ref}{@keys};

    return texify(@args);
}

sub texify {
    my ($ss, $cmd, $s_start, $s_end, $data_js, $sub) = @_;

    $cmd ||= 'rpl_quotes';

    # input data stored as JSON string
    $data_js ||= '';

    if ($data_js) {
        my $coder   = JSON::XS->new->ascii->pretty->allow_nonref;
        $data_input = $coder->decode($data_js);
    }

    my @cmds; 
    push @cmds, 
        str_split($cmd),
        #'trim_eol'
        ;

    $s_start //= $l_start;
    $s_end //= $l_end;

    _str($ss,$s_start,$s_end);

    _do(\@cmds);

    _back($ss);
    return $s_full;
}

sub _acts {
    my @a;
    push @a,
        'rpl_quotes',
        'rpl_dashes',
        'rpl_special',
        ;
    return [@a];
}

sub _do {
    my ($acts) = @_;
    $acts ||= _acts();

    foreach my $x (@$acts) {
        eval $x .'()';
    }
    #q2quotes();
    #rpl_dashes();
    #rpl_special();

}

sub _str {
    my ($ss,$s_start,$s_end) = @_;

    $s_start //= $l_start;
    $s_end //= $l_end;

    if (ref $ss eq 'SCALAR'){ 
        $s = $$ss;
        @split = split("\n" => $s);

    } elsif (ref $ss eq 'ARRAY'){ 
        @split = @$ss;
        $s = join("\n",@split);
    }
    elsif (! ref $ss){ 
        $s = $ss;
        @split = split("\n" => $s);
    }

    if (defined $s_start && defined $s_end) {
        my $i = 1;
        for(@split){
            chomp;

            do { push @before, $_; $i++; next; } if $i < $s_start;
            do { push @after, $_; $i++; next; } if $i > $s_end;

            push @center,$_;
            $i++;
        }

    }else{
        @center = @split;
    }
    $s = join("\n",@center);

}

sub strip_comments {
    my ($ss, $s) = @_;

    #my $s = _str($ss);

    _back($ss, $s);
    return $s;
}

sub _back {
    my ($ss) = @_;

    @center = split("\n",$s);
    @split = (@before,@center,@after);

    $s_full = join("\n",@split);

    if (ref $ss eq 'SCALAR'){
        $$ss = $s_full;

    } elsif (ref $ss eq 'ARRAY'){
        $ss = [ @split ];
    }
}


sub rpl_quotes {
    my ($cmd) = @_;

    $cmd ||= 'enquote';
    #$cmd ||= 'zqq';
    my $start = sprintf(q|\%s{|,$cmd);
    my $end   = q|}|;

    my @c  = split("" => $s);
    my %is = ( qq => 0, q => 0 );
    my @n;

    my $push_qq = sub {
      $is{qq} ^= 1;

      push @n, $start if $is{qq};
      push @n, $end unless $is{qq};
    };

    # opening/closing quotes
    my %br = (
        q{“} => q{”}
    );

    C: while (@c) {
        local $_ = shift @c;
        my $c = $_;

        /"/ && do {
            $push_qq->();
            next;
        };

        ( grep { /^\Q$c\E$/ } keys %br ) && do {
            push @n, $start;
            next;
        };
        ( grep { /^\Q$c\E$/ } values %br ) && do {
            push @n, $end;
            next;
        };

        push @n, $_;
    }

    $s = join("",@n);
}

sub escape_latex {
    local $_ = $s;

    my $escape_s = q{ & % $ # _ { } ~ ^\ };
    my @escape = map { trim($_) } split(" " => $escape_s);

    foreach my $k (@escape) {
        s/\Q$k\E/\\$k/g;
    }
    #

    while(1){
        #s/_/\\_/g;
        #s/%/\\%/g;
        #s/\$/\\\$/g;
        last;
    }

    $s = $_;
}

sub rpl_verbs {
    local $_ = $s;

    s/([^\\]+)\\(\w+)\b/$1\\verb|\\$2|/g;

    $s = $_;
}

# insert empty lines at the end of line
sub expand_vertically {
    _lines();

    for(@lines){
        next if _ln_push($_);

        push @new,$_,'';
    }

    _new2s();
}

sub wrap {
    local $Text::Wrap::columns=80;

    _lines();

    for(@lines){
        next if _ln_push($_);

        push @new,$_ if /^\s*$/;

        my $w = Text::Wrap::wrap('','',$_);

        push @new,split "\n" => $w;
    }

    _new2s();
}

sub expand_punctuation {
    my @c  = split("" => $s);

    local $_ = $s;

    s/\b([,\.\?;!]+)\b/$1 /g;

    $s = $_;
}

sub empty_to_smallskip {
    _lines();

    for(@lines){
        next if _ln_push($_);

        /^\s*$/ && do { 
            push @new,q{\smallskip};
            next;
        };

        push @new,$_;
    }

    _new2s();
}

sub _fbicon_igg {
    my ($chars,$str) = @_;

    my @chars = split "" => $chars;

    my ($name, $prev, $count, @rpl);

    $count = 0;
    while (@chars) {
      my $ch = shift @chars;

      $name = $fbicons{$ch};
      do { push @rpl, $ch; next; } unless $name;

      $count++;
      if (@chars && ( !defined $prev || $prev eq $name )) {
         $prev = $name;
         next;
      }

      my $o = ( $count == 1 ) ? '' : sprintf("{repeat=%s}",$count);
      push @rpl, sprintf('@igg{fbicon.%s}%s',$name,$o);
      $count = 0; $prev = undef;
    }

    my $rpl = ' ' . join(" ",@rpl) . ' ';
    $rpl .= $str if $str;
   
    return $rpl;
}

sub trim_eol {
    my @lines = split "\n" => $s;

    my @new;
    for(@lines){
        s/\s*$//g;
        push @new,$_;
    }

    $s = join("\n",@new);
}

sub _reset { 
    @new = ();
    $flag{$_} = undef for keys %flag;
}

sub _lines { 
    @lines = split "\n" => $s;

    _reset();
}

sub _new2s { 
    $s = join("\n",@new);

    _reset();
}

sub _ln_flag { 
    my ($line) = @_;
    local $_ = $line;

    /^%%%fbauth/ && do { 
        @flag{qw(fbauth)} = ( 1 ); 
    };

    /^%%%endfbauth/ && do { 
        @flag{qw(endfbauth)} = ( undef ); 
    };

    /^%%beginhead/ && do { 
        @flag{qw(head push)} = ( 1, 1 ); 
    };

    /^%%endhead/ && do { 
        @flag{qw(head push)} = ( undef, 1 ); 
    };
    /^\\ifcmt\s*$/ && do { 
        @flag{qw(cmt push)} = ( 1, 1 ); 
    };
    /^\\fi\s*$/ && do { 
        @flag{qw(cmt push)} = ( undef, 1 ); 
    };
    foreach my $k (qw(head cmt)) {
        $flag{push} = 1 if $flag{$k};
    }
}

sub _ln_push { 
    my ($line) = @_;
    local $_ = $line;

    $flag{push} = undef;

    _ln_flag($_);

    push @new,$_ if $flag{push};

    return $flag{push};
}

sub rpl_urls {
    _lines();

    for(@lines){
        next if _ln_push($_);

        my $pat_cmd = sub { 
            my ($ref) = @_; 
            $ref ||= {};
            my $cmd = $ref->{cmd} || 'url';

            #my $r_uri = $RE{URI};
            my $r_uri = '((?:ftp|http)(?:s|):\/\/[^\s,]+)';
            my $s = named_sprintf('(?<!\\\\%(cmd)s\\{)%(r_uri)s',{ cmd => $cmd, r_uri => $r_uri });
            #my $s = sprintf('(?<!\\\\%s\\{)',$cmd);
            #print qq{$s} . "\n";
            #my $pat = qr/$s($RE{URI})/;
            #print Dumper($pat) . "\n";
            #my $pat = qr/$s/;
            #return $pat;
            qr/$s/;
        };
        my $cond = 1;
        my $pat_sub;
        for my $cmd (qw( url Purl )){
            my $pat = $pat_cmd->({ cmd => $cmd });
            $cond = $cond && /$pat/;
            $pat_sub = $pat if /$pat/;

            #print qq{$cond $pat_sub} . "\n";
            last unless $cond;
        }

        $cond && do { 
           my $cmd_url = sub { 
               my $m = $1;
               my @ms = ($m =~ /^(.*)([,]+)$/);
               @ms ? sprintf('\url{%s}%s',@ms) :
                     sprintf('\url{%s}',$m);
           };  

           s/$pat_sub/$cmd_url->()/ge;
        };

        s/\s*$//g;
        push @new,$_;
    }

    _new2s();
}

sub fb_auth {
    my (@lines, @new); 
    @lines = split "\n" => $s;

    for(@lines){

      push @new,$_;
    }

    $s = join("\n",@new);
}

sub ln_emph_to_fbauth {
}

sub fb_iusr {
    _lines();

    for(@lines){
        next if _ln_push($_);

        !$flag{fbauth} && /^\\iusr\{(.*)\}\s*$/ && do { 
            my $iusr = $1;

            my $t = q{
                %%%fbauth
                %%%fbauth_name
                \iusr{%(iusr)s}
                %%%fbauth_name_profile
                %%%fbauth_url
                %%%fbauth_place
                %%%fbauth_place_from
                %%%fbauth_id
                %%%fbauth_front
                %%%fbauth_desc
                %%%fbauth_www
                %%%fbauth_pic
                %%%fbauth_pic profile
                %%%fbauth_pic portrait
                %%%fbauth_pic background
                %%%fbauth_pic other
                %%%fbauth_tags
                %%%fbauth_pubs
                %%%endfbauth
            };
            push @new, map { trim($_) } 
                split "\n" => named_sprintf($t,{ iusr => $iusr })
                ;
            next;
        };

        push @new,$_;
    }

    _new2s();
}

sub jnd {
    _lines();

    my %n = (
      jlines => [@lines],
    );
    my $p = Plg::Projs::Build::Maker::Jnd::Processor->new(%n);

    _new2s();
}

sub fbb {
    _lines();

    my %f = ( au => 1 );
    for(@lines){
        next if _ln_push($_);

        if ($f{au}) {
           push @new,qq/\\iusr{$_}/;
           $f{au} = undef;
           next;
        }

        /^\s*·.*/ && do { 
           $f{au}=1; push @new,''; next; 
        };

        push @new,$_;
    }

    _new2s();
}

sub hyp2ii {
    _lines();

    for(@lines){
       next if /^\s*%/;

       /\\hyperlink\{([^{}]*)\}/ && do { push @new, sprintf(q{\ii{%s}},$1) };
       next;
    }

    _new2s();
}

sub fb_format {
    _lines();

    for(@lines){
        next if _ln_push($_);

        #next if /^\s+· Reply ·/;
        ( /^\s+· Reply ·/ 
          || /^\s+· (\d+)\s+(?:д|ч|г|н)./ 
          || /^\s+· Ответить ·.*/ 
          || /^\s+· Поделиться ·.*/ 
          || /^\s+· Показать перевод.*/
          || /^\s+·\s*$/ 
          || /^Ответить(\d+)/
          || /^ОтветитьПоделиться/
          || /^(\d+)\s*(д|ч|нед|мин|г)\./
          || /^ReplyShare/
          || /^Reply/
          || /^(\d+)(w|d|m|y)/
          || /^See\s+Translation/

          || /^\s*See\s+Translation\s*$/
          || /^\s*Reply\s*$/
          || /^\s*(\d+)(w|d|m|y)\s*$/
        )
        && do { push @new,''; next; };

        my @utf = keys %fbicons;
        my @fbi;
        while(@utf){
          my $k = shift @utf;

          #while(/($k+)/){
          #}
          s/($k+)/_fbicon_igg($1)/ge;
        }

        #s/^\\iusr\{(.*)\}\\par\s*$/\\iusr{$1}/g;
        #s/^\\emph\{(.*)\}\s*$/\\iusr{$1}/g;

        /^\\emph\{(.*)\}\s*$/ && do { 

            push @new, "\\iusr{$1}" ;
            next;
        };

        s/…/.../g;

        push @new,$_;
    }

    _new2s();
}

sub rpl_special {
    local $_ = $s;

    s/_/\\_/g;
    s/%/\\%/g;

    $s = $_;
}

sub sections_up { _sections_shift('up') }
sub sections_down { _sections_shift('down') }

sub _sections_shift {
    my ($id) = @_;

    _lines();

    for(@lines){
      next if _ln_push($_);

      for my $s (@{$secs->{$id}}){
         my @k = keys %$s;
         my $k = shift @k;
         my $v = $s->{$k};

         if (/\\$k/){
            s/$k/$v/g;
            last;
         }
      }
      push @new,$_;
    }

    _new2s();
}

sub delete_empty_lines {
    _lines();

    for(@lines){
      next if _ln_push($_);

      next if /^\s*$/;

      push @new,$_;
    }

    _new2s();
}

sub to_head_center {
}

sub rpl_dashes {
    local $_ = $s;

    s/\s+(-|–)\s+/ \\dshM /g;
    
    $s = $_;
}

1;
 

