
package Plg::Projs::Prj;

use utf8;
use strict;
use warnings;

use FindBin qw($Bin $Script);

use Deep::Hash::Utils qw( deepvalue );

use File::Slurp::Unicode;

use File::Basename qw(basename dirname);
use File::Spec::Functions qw(catfile);
use File::Find::Rule;
use File::Path qw(mkpath rmtree);

use Data::Dumper qw(Dumper);
use DateTime;

use YAML::XS qw( LoadFile );

use Base::XML::Dict qw(xml2dict);
use XML::LibXML::Cache;

use Plg::Projs::Tex qw(
    texify
    texify_ref
    $texify_in
    $texify_out
);

use Base::Git qw(
    git_add
    git_rm
    git_mv
    git_has
);

use Base::DB qw(
    dbh_do
    dbh_create_tables

    dbi_connect

    dbh_select_as_list
    dbh_select
    dbh_select_join
    dbh_select_first

    dbh_insert_hash
    dbh_insert_update_hash

    dbh_delete

    jcond
    cond_where
);

use base qw(
    Base::Opt
    Plg::Projs::Prj::Author
    Plg::Projs::Prj::Data
);

use Base::Arg qw(
    varval

    hash_inject
    hash_update

    dict_update
    dict_expand_env

    opts2dict
);

sub new
{
    my ($class, %opts) = @_;
    my $self = bless (\%opts, ref ($class) || $class);

    $self->init if $self->can('init');

    return $self;
}

sub init_dirs {
    my ($self) = @_;

    my ( $rootid, $proj ) = @{$self}{qw( rootid proj )};
    my $pdfout  = $ENV{PDFOUT} || catfile($ENV{HOME},qw(out pdf));
    my $htmlout = $ENV{HTMLOUT} || catfile($ENV{HOME},qw(out html));

    my $h = {
        pdfout  => $pdfout,
        htmlout => $htmlout,
    };

    if ($rootid) {
        $h = { %$h,
            out_dir_pdf  => catfile($pdfout, $rootid, $proj),
            out_dir_html => catfile($htmlout, $rootid, $proj),
        };
    }

    hash_inject($self, $h);

    return $self;
}

sub init {
    my ($self) = @_;

    $self
        ->init_proj
        ->init_dirs
        ->init_db
        ->init_db_tables
        ;

    return $self;
}

sub prj_load_yml {
    my ($self) = @_;

    return $self if $self->{prj_skip_load_yml};

    my ($proj, $root) = @{$self}{qw( proj root )};

    my $yfile = $self->_prj_yfile;
    return $self unless -f $yfile;

    my $d = LoadFile($yfile) // {};

    $self->{cnf} //= {};
    dict_update($self->{cnf}, $d);

    $self->cnf_trg_list;

    return $self;
}

sub cnf_apply {
    my ($self) = @_;

    my $cnf = $self->{cnf};
    return $self unless $cnf;

    foreach my $x (keys %$cnf) {
        next if $x eq 'targets';

        my $v = $cnf->{$x};

        $self->{$x} //= {};
        if (ref $v eq 'HASH' && ref $self->{$x} eq 'HASH') {
            dict_update($self->{$x}, $v);

        } elsif (ref $v eq 'ARRAY') {
            $self->{$x} = $v;
        }
    }

    return $self;
}

sub cnf_trg_list {
    my ($self) = @_;

    my $proj = $self->{proj};
    my $root = $self->{root};

    my $include = $self->_val_list_ref_('cnf targets include');
    my $exclude = $self->_val_list_ref_('cnf targets exclude');

    my @t;
    my $pat = qr/^$proj\.bld\.(.*)\.yml$/;
    my $rule = File::Find::Rule->new;

    $rule
        ->maxdepth(1)
        ->exec(sub {
            local $_ = shift;
            return unless /$pat/;
            push @t, $1;
        })
        ->in($root);

    my $inc_all = 0;
    $inc_all = ( grep { /^_all_$/ } @$include ) ? 1 : 0;
    $inc_all = 0 if @$exclude;

    my %include = map { $_ => 1 } @$include;
    my %exclude = map { $_ => 1 } @$exclude;
    unless ($inc_all) {
        @t = grep { $include{$_} && !$exclude{$_} } @t;
    }
    $self->{trg_list} = [@t];

    return $self;
}

sub _prj_yfile {
    my ($self) = @_;

    my $proj = $self->{proj};
    my $root = $self->{root};

    my $yfile = catfile($root,sprintf('%s.yml',$proj));
    return $yfile;
}

sub fill_files {
    my ($self) = @_;

    $self->{files} = {};
    foreach my $ext (qw( tex pl dat )) {
        my $r = {
            'exts' => [ $ext ],
        };
        $self->{files}->{$ext} = $self->_files($r);
    }

    return $self;
}

sub _secs_select {
    my ($self, $select) = @_;
    $select ||= {};

    my $keys = [qw( tags author_id )];

    my $list = dbh_select_join({
        dbh => $self->{dbh},

        tbase       => 'projs',
        tbase_alias => 'p',

        f => [qw( sec )],

        keys => $keys,
        key2col => { tags => 'tag' },

        on_key => 'file',

        map { $_ => $select->{$_} } ( @$keys, qw( @op limit where )),
    });

    $DB::single = 1 if $select->{dbg};

    wantarray ? @$list : $list ;
}

sub sec_new_child {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($proj, $sec, $child, $lines) = @{$ref}{qw( proj sec child lines )};
    $proj ||= $self->{proj};

    $self->sec_new({
        proj   => $proj,
        parent => $sec,
        sec    => $child,
    });

    $self->sec_insert_child({
        proj  => $proj,
        sec   => $sec,
        child => $child,
    });

    $self->sec_insert({
        proj  => $proj,
        sec   => $child,
        lines => $lines,
    });

    return $self;
}

sub sec_insert_child {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($sec, $proj, $child) = @{$ref}{qw( sec proj child )};

    my $sd = $self->_sec_data({
        sec  => $sec,
        proj => $proj,
    });

    my $sdc = $self->_sec_data({
        sec  => $child,
        proj => $proj,
    });

    return $self unless $sd && $sd->{'@file_ex'};

    my $file = $sd->{file};

    my $children = $self->_sec_children({
        sec  => $sec,
        proj => $proj,
    });
    return $self if grep { /^$child$/ } @$children;

    my @ii_lines;
    push @ii_lines,
        sprintf('\ii{%s}',$child);

    $self->sec_insert({
        sec  => $sec,
        proj => $proj,
        lines => \@ii_lines,
    });

    my $file_child = $sdc->{file};
    return $self unless $sdc && $sdc->{'@file_ex'};

    # insert children
    my $ins_child = {
       file_parent => $file,
       file_child  => $file_child,
    };

    dbh_insert_update_hash({
       dbh  => $self->{dbh},
       t    => 'tree_children',
       h    => $ins_child,
       uniq => 1,
    });

    return $self;
}

sub db_sec_insert_children {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($sec, $proj, $children) = @{$ref}{qw( sec proj children )};
    return $self unless $children && @$children;

    my $sd = $self->_sec_data({
        sec  => $sec,
        proj => $proj,
    });

    return $self unless $sd && $sd->{'@file_ex'};
    my $file = $sd->{file};

    foreach my $child (@$children) {
        my $sdc = $self->_sec_data({
            sec  => $child,
            proj => $proj,
        });

        next unless $sdc && $sdc->{'@file_ex'};

        my $file_child = $sdc->{file};

        my $ins_child = {
           file_parent => $file,
           file_child  => $file_child,
        };

        dbh_insert_update_hash({
           dbh  => $self->{dbh},
           t    => 'tree_children',
           h    => $ins_child,
           uniq => 1,
        });

    }

    return $self;
}

sub sec_import_x {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $imgman = $ref->{imgman} || $self->{imgman};
    return $self unless $imgman;

    my $rootid = $ref->{rootid} || $self->{rootid};
    my $proj   = $ref->{proj} || $self->{proj};

    my $insert_mode   = $ref->{insert_mode} || 'imgs';

    my ( $sec, $sec_url, $child )   = @{$ref}{qw( sec sec_url child )};
    my ( $tgx, $tags, $headx, $scheme )   = @{$ref}{qw( tgx tags headx scheme )};

    # number of columns for table of images
    my $ncols = @{$ref}{qw( ncols )};

    my $dir = $ref->{dir};

    my $w_db = {
         sec        => $sec,
         proj       => $proj,
         rootid     => $rootid,
         url_parent => $sec_url,
    };

    my $imgs_db = $imgman->_db_imgs({
         tags => { and => [ @$tgx, @$tags ] },
         fields => [qw( url name_orig caption md5 )],
         mode  => 'rows',
         where => $w_db,
    });
    my @imgs_db_md5 = map { $_->{md5} } @$imgs_db;

    my @imgs = $imgman->_fs_find_imgs({
        find  => { max_depth => 1 },
        dirs  => [ $dir ],
        filter => { md5 => [ @imgs_db_md5 ] },
        #limit => 5,
    });

    # does child section have any pictures already in database?
    #my $child_pics = $self->_sec_data_pics({
       #proj => $proj,
       #sec  => $child,
       #cols => [qw( md5 size )],
    #});

    # we import into database all screenshots on the filesystem
    foreach my $img_path (@imgs) {
        $imgman->pic_add({
            file => $img_path,
            tags => [ @$tgx, @$tags ],

            %$w_db,
            mv => 0,
        });
    }

    return $self if $ref->{no_sec_create};

    # we grab all screenshots already in the database
    $imgs_db = $imgman->_db_imgs({
        tags => { and => $tgx },
        where => $w_db,
    });

    return $self unless @$imgs_db;

    $self->sec_new({
        sec    => $child,
        proj   => $proj,
        parent => $sec,
        append => $headx,
        rw     => 1,
    });

    if ($insert_mode eq 'imgs') {
        $self->sec_import_imgs({
            sec    => $child,
            proj   => $proj,
            imgs   => $imgs_db,
            scheme => $scheme,
            ncols  => $ncols,
        });
    }
    elsif ($insert_mode eq 'import') {
    }

    $self->sec_insert_child({
        sec   => $sec,
        proj  => $proj,
        child => $child,
    });

    return $self;
}

sub sec_insert {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($sec, $proj) = @{$ref}{qw( sec proj )};

    # array, lines to be inserted
    my ($lines) = @{$ref}{qw( lines )};
    $lines ||= [];
    return $self unless @$lines;

    my $sd = $self->_sec_data({ sec => $sec, proj => $proj });

    my $file    = $sd && $sd->{file};
    my $file_path = $self->_sec_file_path({ file => $file });
    return $self unless $file_path && -f $file_path;

    my @file_lines = map { chomp; $_ } read_file $file_path;
    push @file_lines, @$lines;

    write_file($file_path,join("\n",@file_lines) . "\n");

    return $self;
}

sub sec_import_imgs {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $scheme = $ref->{scheme} || {};

    my ($sec, $proj, $imgs, $ncols) = @{$ref}{qw( sec proj imgs ncols )};
    $ncols ||= 3;

    my @cmt_lines;
    my $do_last = 1;

    my @col;
    while (@$imgs) {
        # number of pics in the last row
        my $last = $scheme->{last};
        if ($last && $do_last) {
           if (@$imgs == $ncols + $last - 1){
               # ncols and last even, e.g. 3 + 2
               if (($ncols % 2 == 1) && ($last % 2 == 0)) {
                   $ncols--;
                   $do_last = 0;
               }
           }
        }

        @col = splice(@$imgs, 0, $ncols);

        my @pic;
        if (@col > 1) {
            push @pic,
                sprintf('  tab_begin cols=%s,no_fig,center',scalar @col),
                ( map { '    pic ' . $_->{url} } @col ),
                        '  tab_end'
               ;
        } else {
            my $img = shift @col;
            push @pic,
               '  ig ' . $img->{url},
               '  @wrap center',
               '  @width 0.8',
               ;
        }

        push @cmt_lines, '', '\ifcmt', @pic, '\fi', '' ;

    }

    $self->sec_insert({
        sec   => $sec,
        proj  => $proj,
        lines => \@cmt_lines,
    });

    return $self;
}

# see also projs#sec#rename
sub sec_move {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($sec, $proj) = @{$ref}{qw( sec proj )};

    my $sd = $self->_sec_data({ sec => $sec, proj => $proj });
    return $self unless $sd;

    return $self;
}

sub sec_delete {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($sec, $proj) = @{$ref}{qw( sec proj )};

    my $sd = $self->_sec_data({ sec => $sec, proj => $proj });
    return $self unless $sd;

    my $file      = $sd->{file};
    my $file_path = $sd->{'@file_path'};

    my $parents = $self->_sec_parents({
       sec  => $sec,
       proj => $proj,
    });

    foreach my $parent (@$parents) {
       my $sd_parent = $self->_sec_data({
           sec  => $parent,
           proj => $proj,
       });
       my $file_parent = $sd_parent->{file};
       my $txt = read_file $file_parent;

       $texify_in = { 'ii_remove' => [ $sec ] };
       texify_ref({
           ss  => \$txt,
           cmd => 'ii_remove'
       });
       write_file($file_parent,$txt);
    }

    my $ok = dbh_delete({
       dbh => $self->{dbh},
       t => 'projs',
       w => {
         sec  => $sec,
         proj => $proj,
       },
    });

    if ($ok) {
       if (git_has($file_path)) {
          git_rm($file_path);

       }elsif(-f $file_path){
          rmtree $file_path;
       }
    }

    return $self;
}

sub sec_new {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($sec, $parent, $rw) = @{$ref}{qw( sec parent rw )};

    # ARRAY, section lines to be appended
    my ($append) = @{$ref}{qw( append )};

    my ($proj, $root, $rootid) = @{$self}{qw( proj root rootid )};

    my $sd = $self->_sec_data({ sec => $sec, proj => $proj });

    my $file    = $sd && $sd->{file};
    my $file_path = $self->_sec_file_path({ file => $file });
    my $file_ex = $file_path && -f $file_path;

    return $self if $file_ex && !$rw;

    $file = $self->_sec_file({ sec => $sec });
    $file_path = $self->_sec_file_path({ file => $file });

    my @lines = $self->_sec_new_lines({ %$ref });

    write_file($file_path,join("\n",@lines) . "\n");

    git_add($file_path);

    my %other = ( map { defined $ref->{$_} ? ($_ => $ref->{$_}) : () } qw( parent title tags author_id ) );

    if (! $sd) {
        my $ins = {
            sec    => $sec,
            file   => $file,
            proj   => $proj,
            rootid => $rootid,
            %other,
        };
        my $r_ins = {
            dbh => $self->{dbh},
            t => 'projs',
            i => q{INSERT OR IGNORE},
            h => $ins,
        };

        dbh_insert_hash($r_ins);
    }

    return $self;
}

sub _sec_parents {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $proj  = $ref->{proj} || $self->{proj};
    my $sec   = $ref->{sec};

    my $sd = $self->_sec_data({
        sec  => $sec,
        proj => $proj,
    });
    my $file = $sd->{file};

    my $r = {
        dbh   => $self->{dbh},
        q => q{
            SELECT
                projs.sec
            FROM
                projs
            INNER JOIN tree_children
            ON
                projs.file = tree_children.file_parent
            WHERE
                tree_children.file_child = ?
        },
        p     => [ $file ],
    };
    my $parents = dbh_select_as_list($r);

    return $parents;
}

sub _sec_children {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $proj  = $ref->{proj} || $self->{proj};
    my $sec   = $ref->{sec};

    my $sd = $self->_sec_data({
        sec  => $sec,
        proj => $proj,
    });
    my $file = $sd->{file};

    my $r = {
        dbh   => $self->{dbh},
        q => q{
            SELECT
                projs.sec
            FROM
                projs
            INNER JOIN tree_children
            ON
                projs.file = tree_children.file_child
            WHERE
                tree_children.file_parent = ?
        },
        p     => [ $file ],
    };
    my $children = dbh_select_as_list($r);

    return $children;
}

sub _sec_in_db {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $proj  = $ref->{proj} || $self->{proj};
    my $sec  = $ref->{sec};

    my $secs_db = $self->_secs({ proj => $proj });

    return (grep { /^$sec$/ } @$secs_db ) ? 1 : 0;
}

sub _sec_exist {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($sec, $proj, $sd) = @{$ref}{qw( sec proj sd )};

    $sd ||= $self->_sec_data({ sec => $sec, proj => $proj });
    return 0 unless $sd;

    my $ok = 1;

    my $file  = $sd && $sd->{file};
    my $file_path = $self->_sec_file_path({ file => $file });
    my $file_ex = $file_path && -f $file_path;

    $ok = 0 unless $file_ex;

    return $ok;
}

# projs#sec#header
sub _sec_head {
    my ($self, $ref) = @_;
    $ref ||= {};

    foreach my $k (qw( parent url author_id date tags title keymap )) {
        $ref->{$k} //= '';
    }
    $ref->{ext} //= 'tex';

    my ($sec, $parent, $ext) = @{$ref}{qw( sec parent ext )};
    my ($url, $author_id, $date) = @{$ref}{qw( url author_id date )};
    my ($tags, $title, $keymap) = @{$ref}{qw( tags title keymap )};

    my @head;

    if ($ext eq 'tex') {
        push @head,
            $keymap ? '% vim: keymap=' . $keymap : (),
            '%%beginhead ',
            ' ',
            '%%file ' . $sec,
            '%%parent ' . $parent,
            ' ',
            '%%url ' . $url,
            ' ',
            '%%author_id ' . $author_id,
            '%%date ' . $date,
            ' ',
            '%%tags ' . $tags,
            '%%title ' . $title,
            ' ',
            '%%endhead ',
            ;
    }

    return @head;
}

sub _sec_new_lines {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($sec) = @{$ref}{qw(sec)};
    my ($seccmd, $title) = @{$ref}{qw(seccmd title)};
    my ($do) = @{$ref}{qw(do)};
    $do ||= {};
    my $label_str = sprintf(q|\label{sec:%s}|,$sec);

    # append - array to be appended at the end
    # prepend - array to be inserted at the top
    my ($append, $prepend) = @{$ref}{qw(append prepend)};
    $append ||= [];
    $prepend ||= [];

    my @lines;
    push @lines,
       $self->_sec_head($ref),
       @$prepend
       ;

    if ($seccmd && $title){
       push @lines,
         '',
         sprintf(q|\%s{%s}|,$seccmd, $title),
         $label_str,
         '',
         ;
    }

    push @lines, @$append;

    return @lines;
}

sub _sec_file_path {
    my ($self, $ref) = @_;
    $ref ||= {};
    my $root = $ref->{root} || $self->{root};
    my $file = $ref->{file};
    return '' unless $file && $root;

    my $file_path = catfile($root, $file);
    return $file_path;
}

sub sec_load {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $root = $ref->{root} || $self->{root};
    my ($sec, $proj) = @{$ref}{qw( sec proj )};

    my $sd = $self->_sec_data({ sec => $sec, proj => $proj });
    return $self unless $sd && $sd->{'@file_ex'};

    my $file = $sd->{file};
    my $file_path = $sd->{'@file_path'};

    my $txt = read_file $file_path;

    texify_ref({
       ss  => $txt,
       cmd => 'ii_list'
    });
    my $ii_list = $texify_out->{ii_list} || [];

    $self->secs_filter({
       proj => $proj,
       list => $ii_list
    });

    foreach my $ii_sec (@$ii_list) {
       my $sd_ii = $self->_sec_data({
           sec  => $ii_sec,
           proj => $proj,
       });
       next unless $sd_ii;

       my $file_child = $sd_ii->{file};

       # insert children
       my $ins_child = {
          file_parent => $file,
          file_child  => $file_child,
       };

       dbh_insert_update_hash({
          dbh  => $self->{dbh},
          t    => 'tree_children',
          h    => $ins_child,
          uniq => 1,
       });
    }

    return $self;
}

# projs#sec#file

sub _sec_file {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $sec = $ref->{sec} || '';

    my $proj   = $ref->{proj} || $self->{proj};
    my $rootid = $ref->{rootid} || $self->{rootid};
    return unless $sec && $proj;

    my @file_a = $self->_sec_file_a({
        sec    => $sec,
        proj   => $proj,
        rootid => $rootid
    });
    my $file = catfile(@file_a);

    return $file;
}

sub _sec_file_a {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $sec = $ref->{sec} || '';

    my $proj   = $ref->{proj} || $self->{proj};
    my $rootid = $ref->{rootid} || $self->{rootid};

    return () unless $sec && $proj;

    my @file_a;

    my $run_ext = $^O eq 'MSWin32' ? 'bat' : 'sh';

    for($sec){
      /^_main_$/ && do {
          push @file_a, sprintf(q{%s.tex},$proj);
          last;
      };

      /^_main_htlatex_$/ && do {
          push @file_a, sprintf(q{%s.main_htlatex.tex},$proj);
          last;
      };

      for my $k (qw( vim pl zlan sql yml )){
          my $kk = sprintf(q{_%s_},$k);
          /^$kk$/ && do {
              push @file_a, sprintf(q{%s.%s}, $proj, $k);
              last;
          };
      }

      /^_bib_$/ && do {
          push @file_a, sprintf(q{%s.refs.bib},$proj);
          last;
      };

      /^_bld\.(.*)$/ && do {
          my $target = $1;
          push @file_a, sprintf(q{%s.bld.%s.yml}, $proj, $target);
          last;
      };

      /^_perl\.(.*)$/ && do {
          my $sec_pl = $1;
          push @file_a, sprintf(q{%s.%s.pl}, $proj, $sec_pl);
          last;
      };

      /^_pm\.(.*)$/ && do {
          my $sec_pm = $1;
          push @file_a,
            qw( perl lib projs ), $rootid, $proj, sprintf(q{%s.pm},$sec_pm);
          last;
      };

      /^_osecs_$/ && do {
          push @file_a, sprintf(q{%s.secorder.i.dat}, $proj);
          last;
      };

      /^_dat_$/ && do {
          push @file_a, sprintf(q{%s.secs.i.dat}, $proj);
          last;
      };

      /^_dat_defs_$/ && do {
          push @file_a, sprintf(q{%s.defs.i.dat}, $proj);
          last;
      };

      /^_dat_citn_$/ && do {
          push @file_a, sprintf(q{%s.citn.i.dat}, $proj);
          last;
      };

      /^_dat_files_$/ && do {
          push @file_a, sprintf(q{%s.files.i.dat}, $proj);
          last;
      };

      /^_dat_files_ext_$/ && do {
          push @file_a, sprintf(q{%s.files_ext.i.dat}, $proj);
          last;
      };

      # _ii_include_ _ii_exclude_
      foreach my $k (qw( include exclude)) {
          my $kk = sprintf(q{_ii_%s_},$k);
          /^$kk$/ && do {
              push @file_a, sprintf(q{%s.ii_%s.i.dat}, $proj, $k);
              last;
          };
      }

      /^_tex_jnd_$/ && do {
          push @file_a, qw(builds), $proj, qw(src jnd.tex);
          last;
      };

      /^_join_$/ && do {
          push @file_a, qw(joins), sprintf('%s.tex',$proj);
          last;
      };

      foreach my $k (qw( pdflatex perltex htlatex )) {
          my $kk = sprintf(q{_build_%s_},$k);
          /^$kk$/ && do {
              push @file_a, sprintf(q{b_%s_%s_%s}, $proj, $k, $run_ext);
              last;
          };
      }

      push @file_a, sprintf(q{%s.%s.tex},$proj, $sec);
      last;

    }

    return @file_a;
}

sub _dir_sec_new {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $sec    = $ref->{sec} || $self->{sec};
    my $proj   = $ref->{proj} || $self->{proj};
    my $rootid = $self->{rootid};

    my $sub    = $ref->{sub} || '';

    # current cmd data
    my $pic_data = catfile($ENV{PIC_DATA}, $rootid, $proj);
    my $new_dir  = catfile($pic_data, qw(new));

    my $dir_sec_new = catfile($new_dir, $sec, $sub);

    return $dir_sec_new;
}

sub _dir_sec_done {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $sec    = $ref->{sec} || $self->{sec};
    my $proj   = $ref->{proj} || $self->{proj};
    my $rootid = $self->{rootid};

    my $sub    = $ref->{sub} || '';

    # current cmd data
    my $pic_data = catfile($ENV{PIC_DATA}, $rootid, $proj);
    my $done_dir  = catfile($pic_data, qw(done));

    my $dir_sec_done = catfile($done_dir, qw(secs), $sec, $sub);

    my $mfile = catfile($ENV{PLG},qw( projs data yaml months.yaml ));
    my $map_months = LoadFile($mfile) // {};

    if ($sec =~ /^(?<day>\d+)_(?<month>\d+)_(?<year>\d+)\.(\S+)$/) {

        my $dt = DateTime->new( map { $_ => $+{$_} } qw(day month year));

        my $month_name = varval(sprintf('en.short.%s', $dt->month) => $map_months);
        $dir_sec_done = catfile($done_dir, $+{year}, $month_name, $dt->day, $sec, $sub);
    }

    return $dir_sec_done;
}

sub _sec_data {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($proj) = @{$ref}{qw(proj)};
    $proj ||= $self->{proj};

    my $w = { proj => $proj };
    foreach my $x (qw( sec file )) {
        $w->{$x} = $ref->{$x} if $ref->{$x};
    }

    my ($rows, $cols, $q, $p) = dbh_select({
        dbh     => $self->{dbh},
        q       => q{ SELECT * FROM projs },
        w       => $w,
    });
    my $rw = $rows->[0];
    return unless $rw;

    my $file      = $rw->{file};
    my $file_path = $self->_sec_file_path({ file => $file });
    my $file_ex   = $file_path ? -f $file_path : 0;

    hash_update($rw, {
       '@file_path' => $file_path,
       '@file_ex'   => $file_ex,
    });

    my $get = $ref->{'@get'} || [];
    my $wx = { file => $file  };
    my %m = ( 'tags' => 'tag' );
    foreach my $x (@$get) {
        my $f = $m{$x} || $x;
        my $list = dbh_select_as_list({
            dbh     => $self->{dbh},
            q       => qq{ SELECT $f FROM _info_projs_$x },
            w       => $wx,
        });
        hash_update($rw, { '@' . $x => $list });
    }

    return $rw;
}

sub _sec_pic_data {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($proj, $sec) = @{$ref}{qw(proj sec)};

    my $pic_data = [];
    my $ii_list = [ $sec ];

    my $imgman = $self->{imgman};
    return unless $imgman;

    my ($child);
    while (@$ii_list) {
        $child = shift @$ii_list;

        my $imgs = $imgman->_db_imgs({
            fields => [qw( url sec )],
            where => { sec => $child, proj => $proj }
        });
        foreach my $x (@$imgs) {
            my $url = $x->{url};
            my $tags = $imgman->_db_img_tags({ url => $url });
            push @{$pic_data}, { %$x, tags => $tags };
        }

        my $children = $self->_sec_children({ sec => $child, proj => $proj });
        push @$ii_list, @$children;
    }

    return $pic_data;
}

sub _sec_data_pics {
    my ($self, $ref) = @_;
    $ref ||= {};

    my ($proj, $sec, $cols) = @{$ref}{qw(proj sec cols)};
    $proj ||= $self->{proj};
    my $rootid = $self->{rootid};

    # columns to be selected from imgs database, [] for all
    $cols ||= [];

    my $imgman = $self->{imgman};
    my $dbh = $imgman->{dbh};
    return unless $imgman && $dbh;

    my $r_pics = {
        dbh => $dbh,
        t => 'imgs',
        f => $cols,
        w => {
           sec    => $sec,
           proj   => $proj,
           rootid => $rootid,
        }
    };

    my ($rows) = dbh_select($r_pics);

    return $rows;
}

sub _projects {
    my ($self, $ref) = @_;

    $ref ||= {};
    my $pat = $ref->{pat} || '';

    my $projects = [];

    my $r = {
        dbh     => $self->{dbh},
        q       => q{ SELECT DISTINCT proj FROM projs },
        p       => [],
    };

    my ($list,$cols) = dbh_select($r);
    foreach my $row (@$list) {
        my $proj = $row->{proj};
        push @$projects, $proj;
    }

    wantarray ? @$projects : $projects;
}

sub init_proj {
    my ($self) = @_;

    return $self if $self->{proj};

    my ($proj)  = ($Script =~ m/^(\w+)\..*$/);
    my $rootid = basename($Bin);
    my $root    = $Bin;

    my $h = {
        proj     => $proj,
        root     => $root,
        rootid  => $rootid,
    };

    hash_inject($self, $h);

    return $self;
}

sub _db_file {
    my ($self) = @_;

    $self->{db_file} ||= catfile($self->{root},'projs.sqlite');

    return $self->{db_file};
}

sub init_db_tables {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $dbh = $ref->{dbh} || $self->{dbh};
    my $sql_dir = catfile($ENV{PLG},qw( projs data sql ));
    my $table_order = $ref->{table_order} || [qw(
        projs tree_children
        _info_projs_tags
        _info_projs_author_id
        saved
        tag_details
        authors auth_details
    )];
    my $prefix = $ref->{prefix};

    dbh_create_tables({
       dbh         => $dbh,
       sql_dir     => $sql_dir,
       table_order => $table_order,
       prefix => $prefix,
    });

    return $self;
}


sub init_db {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $force = $self->{force};
    return $self if $self->{prj_skip_db} || ($self->{dbh} && !$force);

    if ($force && $self->{dbh}) {
       eval { $self->{dbh}->disconnect; undef $self->{dbh}; };
       if ($@) { warn $@; }
    }

    my $db_file = $self->_db_file;

    my $dbh = dbi_connect({
        dbfile => $db_file
    });
    $self->{dbh} = $dbh;

    return $self;
}

sub secs_filter {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $list = $ref->{list};
    my $proj = $ref->{proj} || $self->{proj};
    return $self unless $list && @$list;

    my @nlist;
    my $secs_db = $self->_secs({ proj => $proj });

    foreach my $x (@$list) {
        next unless ( grep { /^$x$/ } @$secs_db );

        push @nlist, $x;
    }
    @$list = @nlist;

    return $self;
}

sub _secs {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $proj  = $ref->{proj} || $self->{proj};
    my $w = $ref->{w} || {};
    my $limit = $ref->{limit} || 0;

    my $r = {
        dbh => $self->{dbh},
        t   => 'projs',
        f   => [qw(sec)],
        w   => { proj => $proj, %$w },
        $limit ? ( limit => $limit ) : (),
    };

    my $secs = dbh_select_as_list($r);

    wantarray ? @$secs : $secs;
}

sub _files {
    my ($self, $ref) = @_;
    $ref ||= {};

    my $pat  = $ref->{pat} || '';
    my $exts = $ref->{exts} || [];

    my $proj = $self->{proj};

    my $dbh = $self->{dbh};

    my $cond = q{ WHERE proj = ? };
    if (@$exts) {
        $cond .= sprintf(' AND (%s)', join(" OR ",map { sprintf('file LIKE "%%.%s"',$_) } @$exts ));
    }

    my $r = {
        dbh     => $dbh,
        q       => q{ SELECT file, sec FROM projs },
        p       => [ $proj ],
        cond    => $cond,
    };

    my ($list,$cols) = dbh_select($r);

    wantarray ? @$list : $list;

}

1;


