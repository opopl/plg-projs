
package Plg::Projs::Tex;

use strict;
use warnings;
use utf8;

# todo: circular use!
# use Plg::Projs::Build::Maker::Jnd::Processor;

use Data::Dumper qw(Dumper);
use Base::String qw(
    str_split
);

use Base::Arg qw(
    dict2opts
    dict_update
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

use Plg::Projs::Tex::Unicode::Greek;
use Plg::Projs::Tex::Unicode::Japanese;
use Plg::Projs::Tex::Unicode::CJK;

@ISA     = qw(Exporter);
@EXPORT  = qw( );
$VERSION = '0.01';

###our
our( $l_start, $l_end );

our( @lines, @new );

# JSON-decoded input data
our( $data_input );

our( $texify_in, $texify_out );
our $texify_config = {};

our( @split, @before, @after, @center );

our ($s, $s_full);

my @ex_vars_scalar=qw(
    $texify_in
    $texify_out
    $texify_config
);

my @ex_vars_hash=qw(
    %fbicons
    %fbicons_hcode
    %replace_unicode
);

my @ex_vars_array=qw(
);

%EXPORT_TAGS = (
    'funcs' => [qw(
        q2quotes
        texify
        texify_ref

        escape_latex
        unicode2pics

        _fbicon_igg

        pics2tex
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
  '©️ ' => 'copyright',
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
  '🥐' => 'croissant',
  '🔗' => 'link',
  '🟡' => 'yellow.circle',
  '💳' => 'credit.card',
  '🚑' => 'ambulance',
  '🔰' => 'japanese.symbol.for.beginner',
  '✍️'  => 'writing.hand',
  '⚜️'  => 'fleur.de.lis',
  '👑' => 'crown',
  '🥦' => 'broccoli',
  '🐝' => 'honeybee',
  '🟦' => 'blue.square',
  '💊' => 'pill',
  '🚛' => 'lorry.articulated',
  '👟' => 'running.shoe',
  '⚠️' =>  'warning',
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

###fbicons_n
our %fbicons_n = (
  #"\N{U+1F44C}" => '',
  "\N{U+1F3FB}" => '',
  "\N{U+1F3FC}" => '',

  "\N{U+2611}" => 'ballot.box.with.check',

  "\N{U+1F4C4}" => 'page.facing.up',
  "\N{U+1F387}" => 'firework.sparkler',
  "\N{U+1FAB6}" => 'feather',
  "\N{U+1F467}" => 'girl',
  "\N{U+1F37C}" => 'baby.bottle',
  "\N{U+1F37D}" => 'fork.and.knife.with.plate',
  "\N{U+1F455}" => 'tshirt',
  "\N{U+1F9FC}" => 'bar.of.soap',
  "\N{U+1F6CF}" => 'bed',
  "\N{U+1F465}" => 'busts.in.silhouette',
  "\N{U+1F7E5}" => 'large.red.square',
  "\N{U+1F3F0}" => 'european.castle',
  "\N{U+1F3D8}" => 'house.buildings',
  "\N{U+1F52C}" => 'microscope',
  "\N{U+2695}" => 'staff.of.aesculapius',
  "\N{U+1F3EF}" => 'japanese.castle',
  "\N{U+1F985}" => 'eagle',
  "\N{U+1F4BB}" => 'personal.computer',
  #'🎭' => 'performing.arts'
  "\N{U+1F3AD}" => 'performing.arts',
  "\N{U+2665}" => 'heart.suit',
  "\N{U+2764}" => 'heart.red',
  "\N{U+262E}" => 'peace',
  "\N{U+2600}" => 'black.sun.rays',
  "\N{U+2744}" => 'snowflake',
  "\N{U+2603}" => 'snowman',
  "\N{U+1F405}" => 'tiger',
  "\N{U+271D}"  => 'christian.cross',
  "\N{U+1F47B}" => 'ghost',
  "\N{U+1F311}" => 'new.moon',
  "\N{U+1F463}" => 'footprints',
  "\N{U+1FA70}" => 'ballet.shoes',
  "\N{U+1F5E8}" => 'left.speech.bubble',
  "\N{U+1FA96}" => 'military.helmet',
  "\N{U+1F4C6}" => 'tear.off.calendar',
  "\N{U+1F4FD}" => 'film.projector',
  "\N{U+1F4F9}" => 'video.camera',
  "\N{U+1FAD6}" => 'teapot',
  "\N{U+1F9C3}" => 'beverage.box',
  "\N{U+1F964}" => 'cup.with.straw',
  "\N{U+1F354}" => 'hamburger',
  "\N{U+1F9CB}" => 'bubble.tea',
  "\N{U+1F32D}" => 'hotdog',
  "\N{U+1F35F}" => 'french.fries',
  "\N{U+1F355}" => 'slice.of.pizza',
  "\N{U+1F32F}" => 'burrito',
  "\N{U+1F357}" => 'poultry.leg',
  "\N{U+1F356}" => 'meat.on.bone',
  "\N{U+1F953}" => 'bacon',
  "\N{U+1F969}" => 'cut.of.meat',
  "\N{U+1F52E}" => 'crystal.ball',
  "\N{U+1F369}" => 'doughnut',
  "\N{U+1F36C}" => 'candy',
  "\N{U+1F3A7}" => 'headphone',
  "\N{U+2B06}"  => 'upwards.black.arrow',
  "\N{U+1F3A0}" => 'carousel.horse',
  "\N{U+1F3A4}" => 'microphone',
  "\N{U+26F8}"  => 'iceskate',
  "\N{U+1FAA7}" => 'piacard',
  "\N{U+1F3D7}" => 'building.construction',
  "\N{U+1FA7A}" => 'stethoscope',
  "\N{U+1F42C}" => 'dolphin',
  "\N{U+1F537}" => 'large.blue.diamond',
  "\N{U+1F3E3}" => 'japanese.post.office',
  "\N{U+1F39E}" => 'film.frames',

  "\N{U+1F47B}" => 'ghost',
  "\N{U+1F9A2}" => 'swan',
  "\N{U+1F36B}" => 'chocolate.bar',
  "\N{U+23E9}"  => 'right.double.triangle',
  "\N{U+1F550}" => 'clock.face.one.oclock',
  "\N{U+1F4C5}" => 'calendar',
  "\N{U+1F3DB}" => 'classical.building',
  "\N{U+1F553}" => 'clock.face.four.oclock',
  "\N{U+1F556}" => 'clock.face.seven.oclock',
  "\N{U+1F931}" => 'breast.feeding',
  "\N{U+1F536}" => 'large.orange.diamond',
  "\N{U+1F505}" => 'low.brightness.symbol',
  "\N{U+2734}"  => 'eight.pointed.black.star',

  "\N{U+1F570}" => 'mantelpiece.clock',
  "\N{U+270F}" => 'pencil',
  "\N{U+1F58A}" => 'pen.ballpoint',
  "\N{U+1F5A8}" => 'printer',
  "\N{U+270D}" => 'writing.hand',

  "\N{U+1F4CE}" => 'paperclip',
  "\N{U+1F3E4}" => 'postoffice',
  "\N{U+1F3DE}" => 'national.park',
  "\N{U+1F393}" => 'graduation.cap',

  "\N{U+1F41F}" => 'fish',
  "\N{U+1F466}" => 'boy',
  "\N{U+1F936}" => 'mother.christmas',
  "\N{U+261D}" => 'index.pointing.up',
  "\N{U+26A1}" => 'lightning',
  "\N{U+270C}" => 'hand.victory',
  "\N{U+2642}" => 'male.sign',
  "\N{U+1F336}" => 'hot.pepper',
  "\N{U+1F4B8}" => 'money.wings',
  "\N{U+1F4B0}" => 'money.bag',
  "\N{U+1F37B}" => 'cheers',
  "\N{U+1F37A}" => 'beer',
  "\N{U+1F34C}" => 'banana',
  "\N{U+1F977}" => 'ninja',
  "\N{U+2640}" => 'female.sign',
  "\N{U+1F93C}" => 'wrestling',
  "\N{U+1F43B}" => 'bear.face',
  "\N{U+1FAF6}" => 'heart.hands',
  "\N{U+1F3E5}" => 'hospital',
  "\N{U+2714}"  => 'check.mark',
  "\N{U+2B50}"  => 'white.medium.star',
  "\N{U+1F43F}" => 'chipmunk',
  "\N{U+2763}"  => 'heart.exclamation',
  "\N{U+1FAD9}" => 'jar',
  "\N{U+2620}"  => 'skull.crossbones',
  "\N{U+23F3}"  => 'hourglass.flowing.sand',
  "\N{U+1F3D5}"  => 'camping',
  "\N{U+1F587}"  => 'linked.paperclips',
  "\N{U+1F34F}"  => 'green.apple',
  "\N{U+1F34E}"  => 'red.apple',

  "\N{U+1F910}" => 'face.zipper.mouth',
  "\N{U+1FAE4}" => 'face.diagonal.mouth',
  "\N{U+1F31A}" => 'face.new.moon',
  "\N{U+1F628}" => 'face.fearful',
  "\N{U+1F972}" => 'face.smiling.tear',
  "\N{U+1F62B}" => 'face.tired',
  "\N{U+1FAE3}" => 'face.eye.peeking',
  "\N{U+1F60A}" => 'face.smiling.eyes.smiling',
  "\N{U+1F626}" => 'face.frowning.open.mouth',
  "\N{U+1F979}" => 'face.holding.back.tears',
  "\N{U+1F631}" => 'face.screaming.in.fear',

  "\N{U+25B6}" => 'black.play.button',

  "\N{U+25AA}" => 'black.small.square',
  "\N{U+25FC}" => 'black.medium.square',
  "\N{U+2B1C}" => 'white.large.square',
  "\N{U+2139}" => 'information.source',
  "\N{U+23F1}" => 'stopwatch',
  "\N{U+2708}" => 'airplane',
  "\N{U+264E}" => 'libra',
  "\N{U+1F330}" => 'kashtan',
  "\N{U+265F}" => 'black.chess.pawn',
  "\N{U+1FAB2}" => 'beetle',
  "\N{U+1F362}" => 'oden',
  "\N{U+1F36D}" => 'lollipop',
  "\N{U+1F32E}" => 'taco',
  "\N{U+1F968}" => 'pretzel',
  "\N{U+1F9C0}" => 'cheese.wedge',
  "\N{U+1F36F}" => 'honey.pot',
  "\N{U+1F5BC}" => 'framed.picture',
  "\N{U+1F430}" => 'rabbit.face',
  "\N{U+1F407}" => 'rabbit',
  "\N{U+1F95A}" => 'egg',
  "\N{U+2604}"  => 'comet',

  "\N{U+2B07}"  => 'downwards.black.arrow',
  "\N{U+27A1}"  => 'rightwards.black.arrow',
  "\N{U+1F4D1}"  => 'bookmark.tabs',
  "\N{U+1F475}"  => 'older.woman',
  "\N{U+1F9B3}"  => 'white.hair',

  '❤️🩹' => 'heart.white.middle',
  "\N{U+2764}\N{U+FE0F}\N{U+1FA79}" => 'heart.white.middle',
  "\N{U+2764}\N{U+1FA79}" => 'heart.white.middle',
  "\N{U+1FAC2}" => 'people.hugging',

  # replacement character
  "\N{U+FFFD}" => 'u_fffd',

  # Combining Breve
  "\N{U+1F3FF}" => '',

  "\N{U+1FAE0}" => 'face.melting',

  "\N{U+203C}" => "exclamation.mark.double",
  "\N{U+2757}" => 'exclamation.mark',

  "\N{U+2049}" => 'exclamation.question.mark',

  "\N{U+2618}"  => 'shamrock',
  "\N{U+1FA84}" => 'magic.wand',
  "\N{U+2693}"  => 'anchor',
  "\N{U+1F3F5}" => 'rosette',
  "\N{U+1F956}" => "baguette.bread",
  "\N{U+1F35C}" => "steaming.bowl",
  "\N{U+1F9F9}" => 'broom',
  "\N{U+1F36A}" => 'cookie',
  "\N{U+1F9C1}" => 'cupcake',

  "\N{U+2661}"  => 'heart.white.suit',

  "\N{U+1F3ED}"  => 'factory',
  "\N{U+1F3D6}"  => 'beach.with.umbrella',
  "\N{U+1F349}"  => 'watermelon',
  "\N{U+1F991}"  => 'squid',
  "\N{U+1F420}"  => 'tropical.fish',
  "\N{U+1F419}"  => 'octopus',
  "\N{U+1F35E}"  => 'hlib',
  "\N{U+1F43E}"  => 'paw.prints',

  #"\N{U+F0B7}"   => '',

  # G R
  "\N{U+1F1EC}\N{U+1F1F7}" => 'flag.greek',

  "\N{U+1F1E9}\N{U+1F1EA}" => 'flag.germany',
  # A Z
  "\N{U+1F1E6}\N{U+1F1FF}" => 'flag.az',
  "\N{U+1F1F3}\N{U+1F1F1}" => 'flag.nl',
  "\N{U+1F1E8}\N{U+1F1FF}" => 'flag.cz',
  "\N{U+1F1F7}\N{U+1F1FA}" => 'flag.rossia',
  # LT
  "\N{U+1F1F1}\N{U+1F1F9}" => 'flag.litva',
  # C A
  "\N{U+1F1E8}\N{U+1F1E6}" => 'flag.canada',

  #"\N{<++>}" => '<++>',
);

###fbicons_hcode
our %fbicons_hcode = (
  # ruble sign
  "\N{U+20BD}" => '',

  # hryvnia
  "\N{U+20B4}" => '',

  # Combining Acute Accent
  "\N{U+0301}" => '',
  # Combining Grave Accent
  "\N{U+0300}" => '',

  # face.smiling.white
  "\N{U+263A}" => '',

  # face.frowning.white
  "\N{U+2639}" => '',

  # flower
  "\N{U+2698}" => '',

  # invisible comma
  "\N{U+2063}" => '',

  "\N{U+1F3FD}" => '',
  "\N{U+2028}" => '',

  # Latin Small Letter E with Circumflex and Acute
  "\N{U+1EBF}" => '',

);

our %fbicons_hcode_hebrew = map { $_ => '' } (
  "\N{U+05B0}",
  "\N{U+05B4}",
  "\N{U+05B5}",
  "\N{U+05B6}",
  "\N{U+05B7}",
  "\N{U+05B8}",
  "\N{U+05B9}",
  "\N{U+05BC}",
  "\N{U+05D0}",
  "\N{U+05D1}",
  "\N{U+05D2}",
  "\N{U+05D3}",
  "\N{U+05D4}",
  "\N{U+05D5}",
  "\N{U+05D6}",
  "\N{U+05D7}",
  "\N{U+05D8}",
  "\N{U+05D9}",
  "\N{U+05DB}",
  "\N{U+05DC}",
  "\N{U+05DD}",
  "\N{U+05DE}",
  "\N{U+05DF}",
  "\N{U+05E0}",
  "\N{U+05E1}",
  "\N{U+05E2}",
  "\N{U+05E4}",
  "\N{U+05E5}",
  "\N{U+05E7}",
  "\N{U+05E8}",
  "\N{U+05E9}",
  "\N{U+05EA}",
  "\N{U+05F3}",
);

our %fbicons_hcode_georgian = map { $_->{char} => '' } (
  { char => "\N{U+10E9}", name => 'Georgian Letter Chin' },
  { char => "\N{U+10DC}", name => 'Georgian Letter Nar' },
  { char => "\N{U+10D2}", name => 'Georgian Letter Gan' },
  { char => "\N{U+10DB}", name => 'Georgian Letter Man' },
  { char => "\N{U+10D3}", name => 'Georgian Letter Don' },
  { char => "\N{U+10D8}", name => 'Georgian Letter In' },
  { char => "\N{U+10E7}", name => 'Georgian Letter Qar' },
);

our %fbicons_hcode_arabic = map { $_->{char} => '' } (
  { char => "\N{U+0645}", name => 'Arabic Letter Meem' },
  { char => "\N{U+062D}", name => 'Arabic Letter Hah' },
  { char => "\N{U+062F}", name => 'Arabic Letter Dal' },
  { char => "\N{U+0627}", name => 'Arabic Letter Alef' },
  { char => "\N{U+0644}", name => 'Arabic Letter Lam' },
  { char => "\N{U+0631}", name => 'Arabic Letter Reh' },
  { char => "\N{U+0628}", name => 'Arabic Letter Beh' },
  { char => "\N{U+064A}", name => 'Arabic Letter Yeh' },
  { char => "\N{U+0639}", name => 'Arabic Letter Ain' },
  { char => "\N{U+0649}", name => 'Arabic Letter Alef Maksura' },
  { char => "\N{U+0647}", name => 'Arabic Letter Heh' },
  { char => "\N{U+0642}", name => 'Arabic Letter Qaf' },
  { char => "\N{U+0648}", name => 'Arabic Letter Waw' },
  { char => "\N{U+0643}", name => 'Arabic Letter Kaf' },
  { char => "\N{U+0646}", name => 'Arabic Letter Noon' },
  { char => "\N{U+062C}", name => 'Arabic Letter Jeem' },
  { char => "\N{U+0632}", name => 'Arabic Letter Zain' },
);

our %fbicons_hcode_greek = Plg::Projs::Tex::Unicode::Greek::MAP;
our %fbicons_hcode_japanese = Plg::Projs::Tex::Unicode::Japanese::MAP;
our %fbicons_hcode_cjk = Plg::Projs::Tex::Unicode::CJK::MAP;

our %fbicons_hcode_cyrillic = map { $_->{char} => '' } (
  { char => "\N{U+0467}", name => "Cyrillic Small Letter Little Yus" },
  { char => "\N{U+0463}", name => "Cyrillic Small Letter Yat" },
  { char => "\N{U+A657}", name => "Cyrillic Small Letter Iotified A" },

);

%fbicons_hcode = (
    %fbicons_hcode,
    %fbicons_hcode_hebrew,
    %fbicons_hcode_georgian,
    %fbicons_hcode_greek,
    %fbicons_hcode_japanese,
    %fbicons_hcode_cjk,
    %fbicons_hcode_arabic,
    %fbicons_hcode_cyrillic,
);

###replace_unicode
our %replace_unicode = (
  "\N{U+FF08}" => '(',
  "\N{U+FF09}" => ')',
  "\N{U+FF01}" => '!',

  "\N{U+1FAE1}" => "+",

  # minus sign
  "\N{U+2212}" => "-",

  # thin space
  "\N{U+2009}" => " ",

  # square root
  "\N{U+221A}" => "",

  # hyphen bullet
  "\N{U+2043}" => "-",

  # variation selector 16
  "\N{U+FE0F}" => '',

  "\N{U+E206}" => '',
  "\N{U+25AB}" => '',

  # Emoji Modifier Fitzpatrick Type-5 Emoji
  "\N{U+1F3FE}" => '',


  # Object Replacement Character
  "\N{U+FFFC}" => '',

  # Braille Pattern Blank
  "\N{U+2800}" => '',

  # Fullwidth Hyphen-Minus
  "\N{U+FF0D}" => '\\dshM',
  #"\N{U+FF0D}" => '---',

  # Fullwidth Question Mark
  "\N{U+FF1F}" => '?',

  # U+0308 - Combining Diaeresis
  "\x{0456}\x{0308}" => 'ї',
  "е\x{0308}" => 'ё',


);

###fbicons_book
our %fbicons_book = (
  '📘' => 'blue.book',
  '📓' => 'notebook',
  "\N{U+1F4D7}" => 'book.green',
  "\N{U+1F4D9}" => 'book.orange',
  "\N{U+1F4D5}" => 'book.closed',
);

###fbicons
our %fbicons = (
  %fbicons_all,
  %fbicons_book,
  %fbicons_face,
  %fbicons_weak,
  %fbicons_heart,
  %fbicons_person,
  %fbicons_arrows,

  %fbicons_n,
  %fbicons_hcode,
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

# $ss initial full input text
# $s  text to be edited

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

        $texify_config->{n_end_input} = ( $s =~ /\n$/ ) ? 1 : 0;

    } elsif (ref $ss eq 'ARRAY'){
        @split = @$ss;
        $s = join("\n",@split) . "\n";
    }
    elsif (! ref $ss){
        $s = $ss;
        @split = split("\n" => $s);

        $texify_config->{n_end_input} = ( $s =~ /\n$/ ) ? 1 : 0;
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
    $s = join("\n",@center) . "\n";


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

    $s_full = join("\n",@split) . _end_input();

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
        q{“} => q{”},
        q{«} => q{»},
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

sub unicode2pics {
    local $_ = shift || $s;

    my @utf = keys %fbicons;
    my @fbi;
    while(@utf){
      my $k = shift @utf;

      #while(/($k+)/){
      #}
      s/($k+)/_fbicon_igg($1)/ge;
    }

    $s = $_;
    return $s;
}

sub escape_latex {
    local $_ = shift || $s;

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
    return $s;
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

    my $rpl = @rpl ? join(" " => '',@rpl,'') : '';
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



sub _config {
}

sub _end_input {
    $texify_config->{n_end_input} ? "\n" : '';
}

sub _end_tmp {
    $texify_config->{n_end_tmp} ? "\n" : '';
}

sub _new2s {
    $s = join("\n",@new) . _end_tmp();

    _reset();
}

sub _lines {
    $texify_config->{n_end_tmp} = ( $s =~ /\n$/ ) ? 1 : 0;

    @lines = split "\n" => $s;

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

sub pics2tex {
  my ($ref) = @_;
  $ref ||= {};
  my ($pics, $cols_in, $width, $tab_opts) = @{$ref}{qw(pics cols width tab_opts)};
  my ($split, $add_layout) = @{$ref}{qw(split add_layout)};
  my $size = scalar @$pics;
  $cols_in ||= $size;
  $tab_opts ||= {
     'no_fig' => 1,
     'center' => 1,
     'separate' => 1,
  };

  my @begin = ('\ifcmt');
  my @end = ('\fi','');

  my @tex;
  if($size == 1){
    my $pic = shift @$pics;
    my $url = $pic->{url};
    if($url){
      push @tex,
        @begin,
        " ig $url",
        " \@width $width",
        " \@wrap center",
        @end,
        ;
    }
  }else{
    my $cols = $size < $cols_in ? $size : $cols_in;
    #$cols = 2 if $size == 4;
    dict_update($tab_opts,{ cols => $cols });
    if ($add_layout){
        my %ok = map { $_ => 0 } ( 1 .. 5 );
        $ok{3} ||= ($cols == 3) && ($size % $cols == 1);
        $ok{2} ||= ($cols == 2) && ($size % $cols == 1);
        my %lts = (
            3 => '(last.4)2.2',
            2 => '(last.3)3',
        );
        $lts{2} = '2.1' if $size == 3;

        if ($ok{$cols}) {
            my $layout = $lts{$cols};
            dict_update($tab_opts,{ layout => $layout, amount => $size });
            return pics2tex({
               split    => 0,
               add_layout    => 0,
               pics     => $pics,
               cols     => $cols,
               width    => $width,
               tab_opts => $tab_opts
            });
        }
    }
    my $opts_s = dict2opts($tab_opts);
    push @tex, @begin, "tab_begin $opts_s";

    my ($irow, $ipic);
    while(@$pics) {
       $irow = 0 if $irow && $irow == $cols;

       if($split && $size > $cols && @$pics < $cols && !$irow){
         push @tex,
            'tab_end',@end,
            pics2tex({ pics => $pics, width => $width });
         return @tex;
       }

       my $pic = shift @$pics;
       my $url = $pic->{url};
       next unless $url;

       $irow++;
       $ipic++;

       push @tex, '% ' . $ipic, sprintf('   pic %s',$url);
    }
    push @tex, 'tab_end', @end;
  }
  return @tex;
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

sub ii_remove {
    _lines();

    my $ii_remove = $texify_in->{ii_remove} || [];

    for(@lines){
       next if _ln_push($_);

       /^\s*\\ii\{([^{}]*)\}/ && do {
           my $ii = $1;
           next if grep { /^$ii$/ } @$ii_remove;
       };

       push @new, $_;
    }

    _new2s();
}

sub ii_list {
    _lines();

    my $ii_list = [];

    for(@lines){
       next if /^\s*%/;

       /^\s*\\ii\{([^{}]*)\}/ && do { push @$ii_list, $1; };
    }

    $texify_out->{ii_list} = $ii_list;

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

sub list2yaml {
    _lines();

    for(@lines){
        next if _ln_push($_);

        s/^(.*)$/  - '$1'/g;

        push @new,$_;
    }

    _new2s();
}

sub ii2yaml {
    _lines();

    for(@lines){
        next if _ln_push($_);

        s/^\s*\\ii\{(\S+)\}\s*$/  - '$1'/g;

        push @new,$_;
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
          || /^\s*Share\s*$/
          || /^\s*(\d+)(w|d|m|y)\s*$/
          || /^\s*(\d+)(d|w|m|y)Edited\s*/
        )
        #&& do { push @new,''; next; };
        && do { next; };

        my @utf = keys %fbicons;
        my @fbi;
        while(@utf){
          my $k = shift @utf;

          #while(/($k+)/){
          #}
          #s/($k+)/_fbicon_igg($1)/ge;
        }

        #s/^\\iusr\{(.*)\}\\par\s*$/\\iusr{$1}/g;
        #s/^\\emph\{(.*)\}\s*$/\\iusr{$1}/g;

        /^\\emph\{(.*)\}\s*$/ && do {

            push @new, "\\iusr{$1}" ;
            next;
        };

        s/…/.../g;
        s/‘/'/g;
        s/’/'/g;

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

#Missing character: There is no ア (U+30A2) in font Times New Roman Italic/OT:scr
#ipt=latn;language=dflt;!
#Missing character: There is no レ (U+30EC) in font Times New Roman Italic/OT:scr
#ipt=latn;language=dflt;!
#Missing character: There is no ッ (U+30C3) in font Times New Roman Italic/OT:scr
#ipt=latn;language=dflt;!
#Missing character: There is no ク (U+30AF) in font Times New Roman Italic/OT:scr
#ipt=latn;language=dflt;!
#Missing character: There is no ス (U+30B9) in font Times New Roman Italic/OT:scr
#ipt=latn;language=dflt;!
#Missing character: There is no ア (U+30A2) in font Times New Roman Bold/OT:scrip
#t=latn;language=dflt;!
#Missing character: There is no レ (U+30EC) in font Times New Roman Bold/OT:scrip
#t=latn;language=dflt;!
#Missing character: There is no ッ (U+30C3) in font Times New Roman Bold/OT:scrip
#t=latn;language=dflt;!
#Missing character: There is no ク (U+30AF) in font Times New Roman Bold/OT:scrip
#t=latn;language=dflt;!
#Missing character: There is no ス (U+30B9) in font Times New Roman Bold/OT:scrip
#
#Missing character: There is no ☹ (U+2639) in font Times New Roman/OT:script=lat
#n;language=dflt;!
#[116] (./jnd.mw) [117] (./jnd.mw) [118] (./jnd.mw)
#Missing character: There is no ？ (U+FF1F) in font Times New Roman/OT:script=lat
#n;language=dflt;!
#Missing character: There is no ！ (U+FF01) in font Times New Roman/OT:script=lat
#n;language=dflt;!
#Missing character: There is no ⚘ (U+2698) in font Times New Roman/OT:script=lat
#n;language=dflt;!
#Missing character: There is no � (U+1F609) in font Times New Roman/OT:script=la
#tn;language=dflt;!
#Missing character: There is no � (U+1F609) in font Times New Roman/OT:script=la
#tn;language=dflt;!
#Missing character: There is no � (U+1F60A) in font Times New Roman/OT:script=la
#tn;language=dflt;!
#Missing character: There is no � (U+1F609) in font Times New Roman/OT:script=la
#tn;language=dflt;!
#Missing character: There is no  (U+E206) in font Times New Roman/OT:script=lat
#n;language=dflt;!
#Missing character: There is no ❤ (U+2764) in font Times New Roman/OT:script=lat
#n;language=dflt;!

