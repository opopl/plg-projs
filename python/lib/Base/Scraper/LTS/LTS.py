
import os,re,sys,shutil
from pathlib import Path

import hashlib

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Rgx as rgx
import plg.projs.db as projs_db

from bs4 import BeautifulSoup, Comment

from dict_recursive_update import recursive_update

from copy import copy

from plg.projs.Prj.Prj import Prj
from plg.projs.Prj.Section import Section

import jinja2

import yaml

#from lxml.html.clean import Cleaner
#from lxml import etree
#import lxml.html
import lxml

from io import StringIO, BytesIO

from Extern.Pylatex import Package
from Extern.Pylatex.base_classes import Command, Options

#from pylatex import Package
#from pylatex.base_classes import Command, Options

from Base.Mix.mixCmdRunner import mixCmdRunner
from Base.Mix.mixLogger import mixLogger
from Base.Mix.mixLoader import mixLoader
from Base.Mix.mixGetOpt import mixGetOpt
from Base.Mix.mixFileSys import mixFileSys

from Base.Scraper.LTS.ltsAuthor import ltsAuthor
from Base.Scraper.LTS.ltsTarget import ltsTarget

from Base.Zlan import Zlan
from Base.Core import CoreClass

class LTS(
     CoreClass,

     mixLogger,
     mixCmdRunner,
     mixGetOpt,
     mixLoader,
     mixFileSys,

     ltsAuthor,
     ltsTarget,
  ):

  usage='''
  PURPOSE
        This script is for handling LTS
  '''

  opts_argparse = [
    {
       'arr' : '-c --cmd',
       'kwd' : { 'help'    : 'Run command(s)' }
    },
    {
       'arr' : '-s --sec',
       'kwd' : { 'help'    : 'Section(s)' }
    },
    {
       'arr' : '-a --act',
       'kwd' : { 'help'    : 'Actions' }
    },
    {
       'arr' : '-y --f_yaml',
       'kwd' : {
           'help'    : 'input YAML file',
           'default' : '',
       }
    },
  ]

  vars = {
    'mixCmdRunner' : {
      'cmds' : []
    }
  }

  acts = []
  sec = None
  sec_data = {
    'top_lines'  : [],
    'body_lines' : [],
    'head_lines' : [],
    'head_keyval'  : {},
    'seccmd'     : '',
    'sectitle'   : '',
    'save' : {
        'beginhead' : '',
        'endhead'   : '',
        'before_seccmd' : [],
        'before_securl' : [],
    }
  }

  line = None
  flags = {}

  lines = []
  nlines = []

  def __init__(self,args={}):
    self.lts_root  = os.getcwd()
    self.rootid    = Path(self.lts_root).name

    self.html_root = os.environ.get('HTML_ROOT')
    self.img_root  = os.environ.get('IMG_ROOT')

    self.proj      = 'letopis'

    self.db_file_pages = os.path.join(self.html_root,'h.db')
    self.db_file_projs = os.path.join(self.lts_root,'projs.sqlite')
    self.db_file_img   = os.path.join(self.img_root,'img.db')

    self.db_files = {
       'img'   : self.db_file_img,
       'pages' : self.db_file_pages,
       'projs' : self.db_file_projs,
    }

    self.cfg = {
       'fbicons' : {
          'width_tex' : 0.03
       }
    }

    self.prj = Prj({
      'proj'     : self.proj,
      'rootid'   : self.rootid,
      'root'     : self.lts_root,
      'db_file'  : self.db_file_projs,
      'db_files' : self.db_files,
    })

    CoreClass.__init__(self,args)

    self.init()

  def init(self):

    acts = [
      [ 'init_dat_files' ],
      [ 'init_dirs' ],
      [ 'init_tmpl' ],
      [ 'init_db' ],
    ]

    util.call(self,acts)

    return self

  def init_dat_files(self):
    self.dat_files = {}

    kk = [ '', 'fb_', 'vk_', 'yz_' ]
    for k in kk:
      dat_name = f'{k}authors'
      dat_path = os.path.join(self.lts_root, 'data', 'dict', f'{dat_name}.i.dat')
      self.dat_files.update({ dat_name : dat_path })

    self.dat_files.update({
      'fb_groups' : os.path.join(self.lts_root,'data', 'dict', 'fb_groups.i.dat'),
      'names' : os.path.join(self.lts_root,'scrape','bs','in','lists','names_first.i.dat'),
    })

    return self

  def init_dirs(self):

    plg = os.environ.get('PLG')
    self.dirs.update({
      'plg' : plg
    })

    if not self._dir('bin'):
      if self._file('script'):
        self.dirs.update({
            'bin' : str(Path(self._file('script')).parent),
        })
      else:
        if plg:
          self.dirs.update({
            'plg' : plg,
            'bin' : os.path.join(plg,'projs web_scraping py3'),
          })

    self.dirs.update({
      'app_root' : self._dir('bin','lts')
    })

    if not util.get(self,'dirs.tmpl'):
      self.dirs['tmpl'] = self._dir('app_root','tmpl')

    self.dirs.update({
      'lts_root'  : self.lts_root,
      'html_root' : self.html_root,
      'img_root'  : self.img_root,
    })

    plg = os.environ.get('PLG')
    self.dirs.update({
      'tex' : {
         'preambles' : self._dir('plg','lts data tex preambles')
      }
    })

    return self

  def init_tmpl(self):

    env_tex  = jinja2.Environment(
      block_start_string = '\BLOCK{',
      block_end_string = '}',
      variable_start_string = '\VAR{',
      variable_end_string = '}',
      comment_start_string = '\#{',
      comment_end_string = '}',
      line_statement_prefix = '@@',
      line_comment_prefix = '%#',
      trim_blocks = True,
      autoescape = False,
      loader = jinja2.FileSystemLoader(searchpath=self._dir('tmpl','tex'))
    )

    self.template_env_tex = env_tex

    return self

  def _sec_tex_header(self,ref = {}):
    return t

  def _sec_file_data(self,ref = {}):
    sec  = ref.get('sec',self.sec)
    proj = ref.get('proj',self.proj)
    fs   = ref.get('fs',0)

    sec_file = self._sec_file({
      'sec'  : sec,
      'proj' : proj,
      'fs'   : fs
    })
    data = projs_db.get_data(sec_file)

    return data

  def db_import_fs(self,ref = {}):
    proj = ref.get('proj',self.proj)
    exts = ref.get('exts',[])

    exts.append('yml')
    #exts.append('tex')

    root = ref.get('root',self.lts_root)
    rp = Path(root)

    dbw.delete({
      'db_file' : self.db_file_projs,
      'table' : 'projs',
      'where' : {
        '@regexp' : {
          'file' : '\.tml$'
        }
      }
    })

    for ext in exts:
      for f in rp.glob(f'*.{ext}'):
        full_path = f.as_posix()
        fname = f.name

        sec = self._sec_from_file({ 'file' : fname })
        if not sec:
          continue

        data = projs_db.get_data(full_path)

        d = {
          'db_file' : self.db_file_projs,
          'table'   : 'projs',
          'insert'  : {
            'sec'       : sec,
            'file'      : fname,
            'proj'      : proj,
            'tags'      : data.get('tags',''),
            'title'     : data.get('title',''),
            'url'       : data.get('url',''),
            'author_id' : data.get('author_id',''),
          },
          'on_list' : [ 'file' ]
        }

        dbw.insert_update_dict(d)

    return self

  def _sec_from_file(self,ref = {}):
    proj = ref.get('proj',self.proj)

    # section file basename
    file = ref.get('file','')
    if not file:
      return self

    # section, to be determined from fname
    sec = ''

    pat_path = 'files.projs'
    pats = util.get(rgx.pats,pat_path,{})

    for pat_key in pats.keys():
      pat = f'{pat_path}.{pat_key}'
      m = rgx.match(pat,file)
      if not m:
        continue

      m_proj = m.group('proj')
      m_ext = m.group('ext')

      if not m_proj == proj:
        continue

      if pat == 'files.projs.sfile_proj':
        if m_ext == 'tex':
          sec = '_main_'
        elif m_ext == 'vim':
          sec = '_vim_'
        elif m_ext == 'pl':
          sec = '_pl_'
        elif m_ext == 'yml':
          sec = '_yml_'

      elif pat == 'files.projs.sfile':
        m_sec = m.group('sec')

        if m_ext == 'tex':
          sec = m_sec

        elif m_ext == 'yml':
          mm = re.search(r'^bld\.(?P<target>.*)$',m_sec)
          if mm:
            m_target = mm.group('target')
            sec = f'_bld.{m_target}'

        elif m_ext == 'pl':
          sec = f'_perl.{m_sec}'

        elif m_ext == 'bib':
          if sec_m == 'refs':
            sec = '_bib_'

        elif m_ext == 'dat':
          if sec_m == 'ii_include.i':
            sec = '_ii_include_'
          elif sec_m == 'ii_exclude.i':
            sec = '_ii_exclude_'

    return sec

  # section from file, database
  def _sec_file(self, ref = {}):
    sec  = ref.get('sec','')
    proj = ref.get('proj',self.proj)

    # return basename instead of full path
    short = ref.get('short',0)

    # if no database entry, use filesystem logic
    fs    = ref.get('fs',0)

    db_file = self.db_file_projs

    q = 'SELECT file FROM projs WHERE sec = ? AND proj = ?'
    p = [ sec, proj ]
    file = dbw.sql_fetchval(q,p,{ 'db_file' : db_file })

    if not file:
      if not fs:
        return ''
      else:
        file = Section()._file({
          'sec'  : sec,
          'proj' : proj
        })

    sec_file = file
    if not short:
      sec_file = os.path.join( self.lts_root, file )
    #sec_file = os.path.join( self.lts_root, f'{proj}.{sec}.tex' )

    return sec_file

  def _key_remove(self, ids_in = [], ids_rm = []):
    return string.ids_remove(ids_in, ids_rm)

  def _key_merge(self, ids_in = []):
    return string.ids_merge(ids_in)

  def ln_if_body(self,ref={}):
    ok = 1
    ok = ok and self.flags.get('head_done')
    ok = ok and not self.flags.get('eof')
    ok = ok and not self.flags.get('head')

    if not ok:
      return self

    if not self.flags.get('seccmd'):
      self.sec_data['save']['before_seccmd'].append(self.line)

    else:
      if not self.flags.get('securl'):
        self.sec_data['save']['before_securl'].append(self.line)
      else:
        self.sec_data['body_lines'].append(self.line)

    return self

  def ln_if_top(self,ref={}):
    ok = 1
    ok = ok and not self.flags.get('eof')
    ok = ok and not self.flags.get('head')
    ok = ok and not self.flags.get('head_done')

    if not ok:
      return self

    self.sec_data['top_lines'].append(self.line)
    return self

  def ln_if_head(self,ref={}):
    ok = 1
    ok = ok and not self.flags.get('eof')
    ok = ok and self.flags.get('head')
    if not ok:
      return self

    self.sec_data['head_lines'].append(self.line)

    m = rgx.match('tex.projs.head.@key',self.line)
    if not m:
      return self

    m_value = m.group('value')
    m_key   = m.group('key')

    self.sec_data['head_keyval'].update({ m_key : m_value })

    return self

  def ln_shift(self):
    if not len(self.lines):
      self.flags['eof'] = 1
      return self

    self.line = self.lines.pop(0)
    self.line = self.line.strip('\n')

    return self

  def ln_match_head(self):
    if self.flags['eof']:
      return self

    if rgx.match('tex.projs.beginhead', self.line):
      self.flags['head'] = 1
      self.sec_data['save']['beginhead'] = self.line
      self.ln_shift()

    if rgx.match('tex.projs.endhead', self.line):
      self.sec_data['save']['endhead'] = self.line
      if 'head' in self.flags:
        del self.flags['head']
      self.ln_shift()

      self.flags['head_done'] = 1
      self.flags['body'] = 1

    return self

  def ln_match_purl(self):
    ok = 1
    ok = ok and not self.flags.get('eof')
    ok = ok and not self.flags.get('securl')
    if not ok:
      return self

    m = rgx.match('tex.projs.body.purl', self.line)
    if not m:
      return self

    self.flags['securl'] = 1

    self.sec_data['securl'] = m.group(1)

    return self

  def ln_match_seccmd(self):
    ok = 1
    ok = ok and not self.flags.get('eof')
    ok = ok and not self.flags.get('seccmd')
    if not ok:
      return self

    m = rgx.match('tex.projs.seccmd', self.line)

    if not m:
      return self

    self.flags['seccmd'] = 1

    self.sec_data['seccmd']   = m.group(1)
    self.sec_data['sectitle'] = m.group(2)

    return self

  def sec_read(self,ref={}):
    sec       = ref.get('sec','')
    proj      = ref.get('proj',self.proj)

    sec_file = self._sec_file({ 'sec' : sec, 'proj' : proj })

    if not os.path.isfile(sec_file):
      return self

    with open(sec_file,'r') as f:
      self.lines = f.readlines()

      self.sec_data_reset({
        'sec'  : sec,
        'file' : sec_file,
        'proj' : proj,
        'all_lines' : copy(self.lines),
      })
      self.ln_loop()

    return self

  def ln_loop(self,ref={}):
    if not self.lines:
      return self

    self.flags = {}
    self.flags['eof'] = 0
    while len(self.lines):
      self.ln_shift()

      self.ln_match_head()
      self.ln_match_seccmd()
      self.ln_match_purl()
      self.ln_if_head()
      self.ln_if_top()
      self.ln_if_body()

    self.sec_data.update({ 'done' : 1 })

    return self

  # call tree
  #   called by
  #     sec_author_add
  def sec_process(self, ref={}):
    sec       = ref.get('sec','')
    proj      = ref.get('proj',self.proj)

    lines_ref = ref.get('lines',{})

    self.sec_read({ 'sec' : sec, 'proj' : proj })
    self.sec_data_update(lines_ref)
    self.sec_data_gen_lines()
    self.sec_data_save2fs()

    return self

  def sec_data_save2fs(self,ref={}):
    file = self.sec_data.get('file')
    file = ref.get('file',file)

    lines = self.sec_data['all_lines']
    with open(file, 'w', encoding='utf8') as f:
      f.write('\n'.join(lines) + '\n')

  def vimtags_db_create(self, ref = {}):
    db_file = self.db_file_projs

    return self

  def vimtags_update(self, ref = {}):
    tfile = os.path.join(self.lts_root,f'{self.proj}.tags')

    db_file = self.db_file_projs
    tb = 'projs'

    self.vimtags_db_create()

    tlines = []

    q = f'''SELECT sec, file FROM {tb} WHERE proj = ? ORDER BY sec '''
    proj = self.proj

    r = dbw.sql_fetchall(q,[ proj ],{ 'db_file' : db_file })
    rows = r.get('rows')

    for rw in rows:
      sec  = rw.get('sec','')
      file = rw.get('file','')
      if not ( sec and file ):
        continue

      file_path = os.path.join(self.lts_root,file)
      if not os.path.isfile(file_path):
        print(file_path)
        dbw.delete({
          'where'   : { 'sec' : sec, 'proj' : proj },
          'db_file' : db_file,
          'table'   : tb
        })
        continue

      tline = f'''{sec}\t{file_path}\t1'''
      tlines.append(tline)

    ttext = '''!_TAG_FILE_FORMAT 2 /extended format; --format=1 will not append ;" to lines/
!_TAG_FILE_SORTED 1 /0=unsorted, 1=sorted, 2=foldcase/
!_TAG_PROGRAM_AUTHOR  Darren Hiebert  /dhiebert@users.sourceforge.net/
!_TAG_PROGRAM_NAME  Exuberant Ctags //
!_TAG_PROGRAM_URL http://ctags.sourceforge.net  /official site/
!_TAG_PROGRAM_VERSION 5.8 //
'''
    ttext += '\n'.join(tlines) + '\n'
    with open(tfile, 'w', encoding='utf8') as f:
      f.write(ttext)

    return self

  def db_sql_do(self, ref = {}):
    db_id   = ref.get('db_id','')
    db_file = self.db_files.get(db_id,'')

    sql_cmds = ref.get('sql_cmds',[])

    if not db_file:
      return self

    for sql_cmd in sql_cmds:
      print(sql_cmd)
      dbw.sql_do({
        'db_file' : db_file,
        'sql'     : sql_cmd,
      })

    return self

  def _tex_tmpl_render(self, tmpl='', ref={}):
    t = self.template_env_tex.get_template(tmpl)
    text = t.render(**ref)

    return text

  def init_db(self):

    self.prj.init_db()

    return self

  def db_children_fill(self, ref = {}):
    proj = ref.get('proj',self.proj)

    secs  = ref.get('secs',[])

    prj = self.prj

    prj.db_children_fill({
        'proj'  : proj,
        'secs'  : secs,

        'limit' : ref.get('limit'),
        'log'   : ref.get('log'),
    })

    return self

  def db_base2info(self, ref = {}):
    self.prj.db_base2info()

    return self

  def db_secs_list(self, ref = {}):
    pat  = ref.get('pat','')
    ext  = ref.get('ext','')

    pat = 'aa'
    listsecs = self.prj._listsecs({
      'pat' : pat,
      'ext' : ext,
    })
    for sec in listsecs._names():
      print(sec)

    return self

  def _tex_preamble_names(self, ref = {}):
    dir = self._dir('tex.preambles','')
    names = util.find({
      'dirs'    : [dir],
      'inc'     : 'dir',
      'relpath' : 1,
    })
    return names

  def _tex_head(self, ref = {}):
    t = self._tex_tmpl_render('head.tex',ref)

    tex_lines = t.split('\n')
    return tex_lines

  def _tex_preamble(self, ref = {}):
    r_preamble = ref.get('preamble',{})

    if not len(r_preamble):
      # preamble name
      name = ref.get('name','')
      if name:
        names = self._tex_preamble_names()
        if name in names:
          dir = self._dir('tex.preambles',name)
          pack_file = os.path.join(dir,'packs.yaml')
          if os.path.isfile(pack_file):
            r_preamble = { 'pack_file' : pack_file }

    if not len(r_preamble):
      return self

    tex_lines = []

    pack_file = r_preamble.get('pack_file','')
    pack_data = {}
    if os.path.isfile(pack_file):
      with open(pack_file) as f:
        pack_data = yaml.full_load(f)

    if len(pack_data):
      pack_list    = pack_data.get('list',[])
      pack_options = pack_data.get('options',{})

      for pack in pack_list:
        opts = pack_options.get(pack,{})

        opts_bool = []
        opts_dict = {}
        for k, v in opts.items():
           if type(v) in [bool] and v == True:
             opts_bool.append(k)
           else:
             opts_dict.update({ k : v })

        s = Package(pack,options=Options(*opts_bool, **opts_dict)).dumps()
        tex_lines.append(s)

    return tex_lines

  def tex_compile(self, ref = {}):

    return self

  def proj_add_dates(self, ref = {}):

    return self

  def sec_update(self, ref = {}):
    sec     = ref.get('sec',self.sec)
    proj    = ref.get('proj',self.proj)

    keys = util.qw('title url tags author_id date')

    for key in keys:
      if key in ref:
        value = ref.get(key)
        if value == None:
          value = ''

        r = {
            key    : value,
            'proj' : proj,
            'sec'  : sec,
        }
        self.sec_key('set',key,r)

    return self

  # update body lines with callback
  def sec_update_body(self, ref = {}):

    return self

  # update head, only file, no db
  def sec_update_head(self, ref = {}):
    # full file path
    path = ref.get('path','')

    # update self.sec_data['head_keyval'] dict
    update = ref.get('update',{})

    with open(path,'r') as f:
      self.lines = f.readlines()

      self.flags = {}
      self.flags['eof'] = 0

      #self.ln_loop()
      nlines = []
      while len(self.lines):
        if self.flags.get('head_done'):
          # extra line to catch from ln_shift() in ln_match_head()
          nlines.append(self.line)
          nlines.extend(util.list_strip(self.lines))
          break

        self.ln_shift()

        self.ln_match_head()
        self.ln_if_head()
        self.ln_if_top()

    recursive_update(
      self.sec_data['head_keyval'], update
    )
    self.sec_data_gen_head()

    head         = copy(self.sec_data['head_lines'])
    save         = util.get(self,'sec_data.save',{})
    sv_beginhead = save.get('beginhead','%%beginhead')
    sv_endhead   = save.get('endhead','%%endhead')

    head.append(sv_endhead)
    head.insert(0, sv_beginhead)

    while(len(head)):
      hline = head.pop()
      nlines.insert(0, hline)

    txt = '\n'.join(nlines) + '\n'
    with open(path, 'w', encoding='utf8') as f:
      f.write(txt)

    return self

  def sec_update_title(self, ref = {}):
    self.sec_key('set','title',ref)

    return self

  def sec_update_url(self, ref = {}):
    self.sec_key('set','url',ref)

    return self

  # self.sec_data.head_keyval => self.sec_data.head_lines
  def sec_data_gen_head(self):

    head = self.sec_data.get('head_lines')
    kv   = self.sec_data.get('head_keyval')

    # saved lines
    save     = util.get(self,'sec_data.save',{})

    sv_beginhead = save.get('beginhead','%%beginhead')
    sv_endhead = save.get('endhead','%%endhead')

    for i in range(0,len(head)):
      m = rgx.match('tex.projs.head.@key', head[i])
      if m:
        hval = m.group('value')
        hkey = m.group('key')
        if hkey in kv:
          new = kv.get(hkey)
          if not new == None:
            head[i] = f'%%{hkey} {new}'

    return self

  # (re-)generate all_lines from sec_data
  def sec_data_gen_lines(self):
    top  = self.sec_data.get('top_lines')
    head = self.sec_data.get('head_lines')
    body = self.sec_data.get('body_lines')
    kv   = self.sec_data.get('head_keyval')

    securl   = util.get(self,'sec_data.securl')
    sectitle = util.get(self,'sec_data.sectitle')
    seccmd   = util.get(self,'sec_data.seccmd')
    sec      = util.get(self,'sec_data.sec')

    # saved lines
    save     = util.get(self,'sec_data.save',{})

    sv_beginhead = save.get('beginhead','%%beginhead')
    sv_endhead = save.get('endhead','%%endhead')
    sv_before_seccmd = save.get('before_seccmd',[])

    for i in range(0,len(head)):
      m = rgx.match('tex.projs.head.@key', head[i])
      if m:
        hval = m.group('value')
        hkey = m.group('key')
        if hkey in kv:
          new = kv.get(hkey)
          if not new == None:
            head[i] = f'%%{hkey} {new}'

    nbody = []
    nbody.extend(sv_before_seccmd)
    if not seccmd:
      seccmd = 'subsection'

    kv_title = kv.get('title','')
    if kv_title:
      nbody.append(f'\{seccmd}' + '{' + kv_title + '}')
      nbody.append('\label{sec:' + sec + '}')
      nbody.append(' ')

    kv_url = kv.get('url','')
    if kv_url:
      nbody.append('\Purl{' + kv_url + '}')

    kv_aid = kv.get('author_id','')
    if kv_aid and kv_title:
      aa = [
        '\ifcmt',
        ' author_begin',
        f'   author_id {kv_aid}',
        ' author_end',
        "\\fi",
      ]
      nbody.extend(aa)

    flg = { 'seccmd' : 0 }
    while len(body):
      ln = body.pop(0).strip('\n')

      m = rgx.match('tex.projs.body.purl',ln)
      if m:
        purl = m.group(1)
        if purl == securl:
          continue

      m = rgx.match('tex.projs.body.label_sec',ln)
      if m:
        ln_sec   = m.group(1)
        if ln_sec == sec:
          continue

      m = rgx.match('tex.projs.seccmd',ln)
      if m:
        flg['seccmd'] = 1
        ln_seccmd   = m.group(1)
        ln_sectitle = m.group(2)
        if ln_seccmd == seccmd and ln_sectitle == sectitle:
          continue

      if not rgx.match('tex.projs.ifcmt',ln):
        nbody.append(ln)
        continue

      ln_cmt = []
      while len(body):
        ln = body.pop(0).strip('\n')
        if rgx.match('tex.projs.cmt.author_begin',ln):
          continue
        elif rgx.match('tex.projs.cmt.author_end',ln):
          continue
        elif rgx.match('tex.projs.cmt.author_id',ln):
          continue
        elif rgx.match('tex.projs.fi',ln):
          break
        # non-empty string
        elif len(ln.strip()):
          ln_cmt.append(ln)
        else:
          continue

      if len(ln_cmt):
        nbody.append("\\ifcmt")
        nbody.extend(ln_cmt)
        nbody.append("\\fi")

    lines = []
    lines.extend(top)
    lines.extend([sv_beginhead])
    lines.extend(head)
    lines.extend([sv_endhead])
    lines.extend(nbody)

    self.sec_data['all_lines'] = lines

    return self

  def sec_data_update(self, ref = {}):
    if not self.sec_data['done']:
      return self

    actions = ref.get('actions',[])

    for action in actions:
      name = action.get('name','')
      args = action.get('args',[])

      if len(args):
        kv = args[0]
        for key, value in kv.items():
          if value in [ None,'' ]:
            continue

          old = util.get(self, f'sec_data.head_keyval.{key}','')

          new = None
          if name in [ '_key_set' ]:
            new = value

          elif name in [ '_key_merge' ]:
            new = string.ids_merge(ids_in = [ old, value ])

          elif name in [ '_key_remove' ]:
            new = string.ids_remove(ids_in = [ old ], ids_remove = [ value ])

          if not new in [ None ]:
            self.sec_data['head_keyval'].update({ key : new })

    return self

  def sec_data_reset(self,ref={}):
    self.sec_data = {
      # section name
      'sec'  : '',
      # full path sec_file
      'file'  : '',
      # project name
      'proj' : '',
      # section data has been imported into sec_data?
      'done' : 0,
      # lines before head block
      'top_lines' : [],
      # lines after head block
      'body_lines' : [],
      # beginhead ... endhead lines
      'head_lines' : [],
      # keys from head block
      'head_keyval' : {},
      # e.g. subsection
      'seccmd' : '',
      'securl' : '',
      # title inside seccmd command
      'sectitle' : '',
      # all lines
      'all_lines' : [],
      # saved
      'save' : {
        'beginhead' : '',
        'endhead'   : '',
        'before_seccmd' : [],
        'before_securl' : [],
      }
    }
    self.sec_data.update(ref)

    return self

  def sec_rename(self, ref = {}):
    proj = ref.get('proj',self.proj)

    old = ref.get('old','')
    new = ref.get('new','')
    if not (old and new and proj):
      return self

    sd_old = self.prj._sec_data({
       'proj' : proj,
       'sec'  : old,
    })

    sd_new = self.prj._sec_data({
       'proj' : proj,
       'sec'  : new,
    })
    # old should exist in db and fs
    # new is absent
    ok = 1
    ok = ok and sd_old
    ok = ok and sd_old.get('@file_ex')
    ok = ok and not sd_new

    if not ok:
      return self

    old_path = sd_old.get('@file_path')
    new_path = self._sec_file({
       'proj' : proj,
       'sec'  : new,
       'fs'   : 1,
    })

    if not new_path:
      return self

    git_old = util.git_has(old_path)

    self.sec_update_head({
        'path' : old_path,
        'update' : {
           # file key in head means sec
           'file' : new,
        }
    })

    ok = dbw.update_dict({
      'db_file' : self.db_file_projs,
      'table' : 'projs',
      'where' : {
         'proj' : proj,
         'sec'  : old,
      },
      'update' : {
         'sec'  : new,
         'file' : Path(new_path).name,
      }
    })
    if not ok:
      # rollback head section
      self.sec_update_head({
          'path' : old_path,
          'update' : { 'file' : old }
      })
      return self

    if git_old:
      util.git_move(old_path, new_path)
    else:
      shutil.move(old_path, new_path)

    return self

  # given section name, simply create it:
  #    write to file, add to database
  def sec_new(self, ref = {}):
    sec = ref.get('sec','')
    if not sec:
      return self

    s_head = self._tex_tmpl_render('head.tex',ref)
    s_content = self._tex_tmpl_render('sec.tex',ref)

    s = '\n'.join([ s_head, s_content ]) + '\n'

    sec_file = self._sec_file({ 'sec' : sec })
    with open(sec_file, 'w', encoding='utf8') as f:
      f.write(s)

    return self

  def sec_new_date(self, ref = {}):
    date      = ref.get('date','')

    return self

  def _fbicons_db(self):
    db_file  = self.db_file_img

    names = dbw.select({
      'table'   : 'imgs',
      'db_file' : db_file,
      'select' : 'name',
      'orderby' : { 'name' : 'asc' },
      'output' : 'list',
      'where' : {
         '@like' : { 'name' : 'fbicon%' }
      }
    })
    fbicons = []
    for name in names:
      m = re.match(r'^fbicon\.(.*)$',name)
      if m:
        fbi = m.group(1)
        fbicons.append(fbi)

    return fbicons

  def _fbicon_db(self, ref = {}):
    db_file  = self.db_file_img

    name = ref.get('name')

    rw = dbw.select({
      'table'   : 'imgs',
      'db_file' : db_file,
      'output' : 'first_row',
      'where' : { 'name' : name }
    })

    img = rw.get('img')
    if img:
      rw.update({
         'img_file' : self._dir('img_root',[ img ])
      })

    return rw

  def _tex_ig(self, ref = {}):
    width = ref.get('width')
    file  = ref.get('file')

    if not os.path.isfile(file):
      ig = ''
    else:
      iga = [
        f'''\\includegraphics[width={width}\\textwidth]''',
        '{', file, '}'
      ]
      ig = ''.join(iga)

    return ig

  def db_fbicons_list(self, ref = {}):
    width_tex = util.get(self,'cfg.fbicons.width_tex',0.05)

    sec = 'list.fbicons'
    list_file = self._sec_file({ 'sec' : sec })

    fbicons = self._fbicons_db()

    tex_preamble = self._tex_preamble({
      'name' : 'core'
    })

    tex_head = self._tex_head({
      'sec' : sec
    })
    tex_lines = []
    tex_lines.extend(tex_head)

    tex_lines.append('\\begin{tabular}{*{2}{l}}')

    tex_tab_rows = []
    for fbi in fbicons:
      name = f'fbicon.{fbi}'
      fbi_data = self._fbicon_db({ 'name' : name })
      img_file  = fbi_data.get('img_file','')
      wt = fbi_data.get('width_tex',width_tex)
      ig = self._tex_ig({
        'file'  : img_file,
        'width' : wt,
      })

      tex_row = ' & '.join([ ig, fbi ]) + '\\\\'
      tex_lines.append(tex_row)

    tex = tex_lines.append('\\end{tabular}')

    tex = '\n'.join(tex_lines) + '\n'
    with open(list_file, 'w', encoding='utf8') as f:
      f.write(tex)

    return self

  def db_fbicons_update(self, ref = {}):
    db_file  = self.db_file_img

    width_tex = util.get(self,'cfg.fbicons.width_tex',0.05)

    q = '''SELECT * FROM imgs WHERE name LIKE 'fbicon%' '''
    r = dbw.sql_fetchall(q,[ ],{ 'db_file' : db_file })
    rows = r.get('rows',[])
    for rw in rows:
      name = rw.get('name')
      dbw.update_dict({
         'db_file' : db_file,
         'table' : 'imgs',
         'update' : { 'width_tex' : width_tex },
         'where' : { 'name' : name },
      })

    return self

  # collect \iusr occurences into database
  def iusr2db(self,ref={}):

    return self

  def db_update_auth_details(self, ref = {}):
    db_file  = self.db_file_pages

    q = 'SELECT id FROM authors'
    auth_ids = dbw.sql_fetchlist(q,[],{ 'db_file' : db_file })
    for id in auth_ids:
      d = {
         'db_file' : db_file,
         'table'   : 'auth_details',
         'insert' : { 'id' : id },
         'on_list' : [ 'id' ]
      }
      dbw.insert_update_dict(d)

    return self

  def db_img_base2info(self, ref = {}):

    tbase = 'imgs'

    jcol  = 'url'
    b2i   = { 'tags' : 'tag' }
    bcols = [ 'tags' ]
    where = {}

    dbw.base2info({
      'db_file' : self.db_file_img,
      'tbase'   : tbase,
      'bwhere'  : where,
      'jcol'    : jcol,
      'b2i'     : b2i,
      'bcols'   : bcols
    })

    return self

  def db_img_md5(self, ref = {}):

    limit = 10
    q = f'''SELECT inum, img, md5 FROM imgs WHERE md5 IS NOT NULL LIMIT {limit}'''
    p = []

    r  = dbw.sql_fetchall(q, p, { 'db_file' : self.db_file_img })
    rows = r.get('rows',[])

    for rw in rows:
      inum   = rw.get('inum')
      img    = rw.get('img')
      md5_db = rw.get('md5')

      img_file = os.path.join(self.img_root,img)
      if not os.path.isfile(img_file):
        continue

      with open(img_file,"rb") as f:
        b = f.read() # read file as bytes
        md5 = hashlib.md5(b).hexdigest()

      print(rw)

    return self

  def db_update_img(self, ref = {}):
    img_data = ref.get('img_data',[])
    db_file  = self.db_file_img

    for d_img in img_data:
      url = d_img.get('url','')
      if not url:
        continue

      d = {
        'db_file' : db_file,
        'table'   : 'imgs',
        'insert'  : d_img,
        'on_list' : [ 'url' ]
      }

      dbw.insert_update_dict(d)

    return self


  #let cnt = projs#sec#count_ii({ 'ii_prefix' : ii_prefix })
  def _sec_count_ii(self, ref = {}):
    ii_prefix = ref.get('ii_prefix','')

    q = f'''SELECT COUNT(*) FROM projs WHERE sec LIKE "{ii_prefix}%%" '''

    cnt = dbw.sql_fetchval(q,[],{ 'db_file' : self.db_file_projs })

    return cnt

  def _fb_data(self, ref = {}):
    url       = ref.get('url','')

    u = util.url_parse(url)
    fb_data = None

    m = rgx.search('url.facebook.base',u['host'])
    if not m:
      return

    fb_id = None
    post_id = None

    if rgx.match('url.facebook.permalink',u['path']):
      fb_id   = u['query_p'].get('id','')
      post_id = u['query_p'].get('story_fbid','')

      if fb_id and post_id:
         url = util.url_join('https://www.facebook.com',f'/{fb_id}/posts/{post_id}')
         u = util.url_parse(url)

    else:
      m_path = rgx.match('url.facebook.post_user',u['path'])

      if m_path:
        fb_id = m_path.group(1)
        post_id = m_path.group(2)

    fb_data = {
      'fb_id'   : fb_id,
      'post_id' : post_id,
    }

    return fb_data

  def _sec_ii_prefix(self, ref = {}):
    parent    = ref.get('parent','')
    url       = ref.get('url','')

    author_id = ref.get('author_id','')

    ii_prefix = f'{parent}.'

    fb_data = self._fb_data({ 'url' : url })
    if fb_data:
      fb_id = fb_data.get('fb_id','')

      if fb_id:
        auth = self._auth_data({ 'fb_id' : fb_id })
        if auth:
          author_id = auth.get('id')

    if author_id:
      ii_prefix = f'{ii_prefix}fb.{author_id}.'

    cnt = self._sec_count_ii({ 'ii_prefix' : ii_prefix })
    inum = cnt + 1

    ii_prefix = f'{ii_prefix}{inum}.'

    return ii_prefix

  def sec_new_ii_url(self, ref = {}):
    # parent section
    parent    = ref.get('parent','')

    url       = ref.get('url','')
    title     = ref.get('title','')
    author_id = ref.get('author_id','')

    # section to be created
    sec       = ref.get('sec','')

    # final part of the section full name
    ii_sec    = ref.get('ii_sec','')

    date      = ref.get('date','')

    tags      = ref.get('tags','')

    seccmd    = ref.get('seccmd','')

    ii_prefix = self._sec_ii_prefix({
      'parent' : parent,
      'url'    : url,
    })

    print(f'ii_prefix => {ii_prefix}')

    t = self.template_env_tex.get_template("sec.tex")

    h = t.render(
        author_id = author_id,
        date = date,
        parent = parent,
        sec = sec,
        seccmd = seccmd,
        tags = tags,
        title = title,
        url = url,
    )

    sec_file = self._sec_file({ 'sec' : sec })

    #print(h)

    return self

  def _fbauth_list_fs(self):
    fbauth_secs = self._fbauth_secs_fs()
    fbauth_list = []
    for sec in fbauth_secs:
      m = re.match(r'fbauth\.(.*)$',sec)
      if m:
        fba = m.group(1)
        fbauth_list.append(fba)

    return fbauth_list

  def _fbauth_secs_fs(self):
    p = Path(self._dir('lts_root'))

    fbauth_secs = []
    for pp in p.glob(f'{self.proj}.fbauth.*.tex'):
      pp_file = pp.name
      m = re.match(rf'^{self.proj}\.(.*)\.tex$',pp_file)
      if not m:
        continue

      sec = m.group(1)
      fbauth_secs.append(sec)

    fbauth_secs.sort()

    return fbauth_secs

  def fbauth_list_fs(self, ref = {}):
    fbauth_list = self._fbauth_list_fs()
    for fba in fbauth_list:
      print(fba)

    return self

#http://eosrei.net/articles/2015/11/latex-templates-python-and-jinja2-generate-pdfs
#https://web.archive.org/web/20121024021221/http://e6h.de/post/11/
  def fbauth_new(self, ref = {}):
    lines = []

    fba = ref.get('fba','')
    if not fba:
      return self

    head_data   = ref.get('head_data',{})
    fbauth_data = ref.get('fbauth_data',{})

    fbauth_data = util.dict_str2int(fbauth_data, keys = [ 'friend' ])
    fbauth_data = util.dict_none2str(fbauth_data)
    #fbauth_data = util.dict_none_rm(fbauth_data)

    t = self.template_env_tex.get_template("head.tex")
    s_head = t.render(**head_data)

    t = self.template_env_tex.get_template("fbauth.tex")
    s_fbauth = t.render(**fbauth_data)

    lines.extend(s_head.split('\n'))
    lines.extend([ '' ])
    lines.extend(string.split_n_trim(s_fbauth))
    #lines.extend(s_fbauth.split('\n'))

    t = '\n'.join(lines) + '\n'

    sec = f'''fbauth.{fba}'''
    sec_file = self._sec_file({ 'sec' : sec })

    with open(sec_file, 'w', encoding='utf8') as f:
      f.write(t)

    insert = {
      'sec'    : sec,
      'proj'   : self.proj,
      'rootid' : self.rootid,
      'file'   : Path(sec_file).name,
    }

    dbw.insert_dict({
      'db_file' : self.db_file_projs,
      'table'  : 'projs',
      'insert' : insert
    })

    return self

  def fbauth_join(self, ref = {}):
    f_join = self._dir('lts_root',f'{self.proj}.fbauth_join.tex')

    lines_join = []

    fbauth_secs = self._fbauth_secs_fs()
    for sec in fbauth_secs:
      lines_join.append('\ii{%s}' % sec)

    text_join = '\n'.join(lines_join) + '\n'

    with open(f_join, 'w', encoding='utf8') as f:
      f.write(text_join)

    return self

  def sec_list_iusr(self, ref = {}):
    sec   = ref.get('sec',self.sec)

    iusr = []
    sec_file = self._sec_file({ 'sec' : sec })
    with open(sec_file,'r') as f:
      lines = f.readlines()
      for line in lines:
        m = re.match(r'\\iusr\{(?P<name>.*)\}\s*$',line)
        if m:
          name = m.group('name')
          if name and not name in iusr:
            iusr.append(name)

    if len(iusr):
      iusr.sort()
      for name in iusr:
        print(name)

    return self

  def html_xpath(self, ref = {}):
    xpath = ref.get('xpath')
    file  = ref.get('file')

    unwrap = util.get('preprocess.unwrap')

    with open(file,'r') as f:
      html = f.read()

    self.etree = lxml.etree
    hp = lxml.etree.HTMLParser(encoding='utf-8')

    if unwrap:
      self.soup = BeautifulSoup(html,'html5lib',from_encoding='utf-8')
      for k in ['div','span']:
        while 1:
          div = self.soup.select_one(k)
          if not div:
            break
          div.unwrap()

      html = self.soup.prettify()
      with open('p_w.html', 'w') as f:
        f.write(self.soup.prettify())

    self.xtree = lxml.etree.parse(StringIO(html),parser=hp)
    self.xroot = self.xtree.getroot()

    out = []
    try:
       elems = self.xroot.xpath(xpath)
       for elem in elems:
         txt = None
         n = type(elem).__name__
         if n in [ 'HtmlElement','_Element' ]:
           txt = self.etree.tostring(
                   elem,
                   encoding='unicode',
                   pretty_print=True)
         elif n == '_ElementUnicodeResult':
           txt = elem.__str__()
         out.append(txt)
    except:
       e = sys.exc_info()
       print(f'[xpath]: {e}')

    t = '\n'.join(out) + '\n'
    print(t)
    #t = f'<div>{t}</div>'
#    trx = lxml.etree.parse(StringIO(t), hp)
    #tt = lxml.etree.tostring(
         #trx,
         #pretty_print=True,
    #)
    #print(tt)
    with open('p_xpath.html', 'w', encoding='utf8') as f:
        f.write(t)
    #for ln in out:
       #print(ln)

    return self

  def sec_delete(self, ref = {}):
    proj = ref.get('proj', self.proj)

    prj = self.prj

    refin = copy(ref)
    refin.update({ 'proj' : proj })

    prj.sec_delete(refin)

    return self

  def sec_key(self, act='', key='', ref = {}):
    sec    = ref.get('sec',self.sec)
    proj   = ref.get('proj',self.proj)

    value  = ref.get(key,'') or ''

    map = {
      'add' : '_key_merge',
      'rm'  : '_key_remove',
      'set' : '_key_set',
    }
    name = map.get(act,'')

    lines_ref = {
      'actions' : [
          {
            'name' : name,
            'args' : [ { key : value } ]
          }
       ]
    }

    self.sec_process({
      'lines' : lines_ref,
      'sec'   : sec,
      'proj'  : proj,
    })

    self.sec_file2db({ 'sec' : sec, 'proj' : proj })

    return self

  def sec_db_children_push(self, ref = {}):
    sec      = ref.get('sec',self.sec)
    proj     = ref.get('proj',self.proj)
    children = ref.get('children',[])

    prj = self.prj
    prj.db_sec_insert_children({
       'proj'     : proj,
       'sec'      : sec,
       'children' : children,
    })

    return self

  # get children from 'ii' statements and then fill
  #     tree_children database
  def sec_children_from_ii(self, ref = {}):

    return self

  # remove from database and filesystem
  def sec_children_delete(self, ref = {}):
    prj = self.prj

    sec   = ref.get('sec',self.sec)
    proj  = ref.get('proj',self.proj)

    prj.sec_children_delete({
       'proj' : proj,
       'sec'  : sec,
    })

    return self

  # work via Section.py
  def sec_db_add_section(self, ref = {}):
    sec   = ref.get('sec',self.sec)
    proj  = ref.get('proj',self.proj)

    section = Section(ref)
    prj = self.prj

    prj.add(section)

    return self

  def sec_db_update(self, ref = {}):
    sec   = ref.get('sec',self.sec)
    proj  = ref.get('proj',self.proj)

    data  = ref.get('data',{})

    where = {
      'sec'  : sec,
      'proj' : proj,
    }

    db_file = self.db_file_projs

    d = {
      'db_file' : db_file,
      'table'   : 'projs',
      'insert'  : {
        'sec'       : sec,
        'proj'      : proj,
        'tags'      : data.get('tags',''),
        'title'     : data.get('title',''),
        'url'       : data.get('url',''),
        'author_id' : data.get('author_id',''),
      },
      'on_list' : [ 'sec', 'proj' ]
    }

    dbw.insert_update_dict(d)

    tbase = 'projs'

    jcol  = 'file'
    b2i   = { 'tags' : 'tag' }
    bcols = [ 'tags', 'author_id' ]

    dbw.base2info({
      'db_file' : self.db_file_projs,
      'tbase'   : tbase,
      'bwhere'  : where,
      'jcol'    : jcol,
      'b2i'     : b2i,
      'bcols'   : bcols
    })

    return self

  def sec_file2db(self, ref = {}):
    sec    = ref.get('sec',self.sec)
    proj   = ref.get('proj',self.proj)

    data = self._sec_file_data({
      'sec'  : sec,
      'proj' : proj,
    })

    if sec and len(data):
      self.sec_db_update({
        'sec'  : sec,
        'proj' : proj,
        'data' : data,
      })

    return self

  # site info in hosts.yaml => authors database info
  def db_sites2auth(self, ref = {}):
    hosts_yaml =  os.path.join(self.lts_root,'scrape','bs','in','hosts.yaml')

    if not hosts_yaml or not os.path.isfile(hosts_yaml):
      return self

    with open(hosts_yaml) as f:
      d = yaml.full_load(f)
      for host_pats, host_info in d.items():
        site = host_info.get('site','')
        auth = host_info.get('author',{})
        if not len(auth):
          continue

        name = auth.get('name','')
        if name:
          d = {
            'db_file' : self.db_file_projs,
            'table'   : 'authors',
            'insert'  : {
               'id'    : site,
               'name'  : name,
               'plain' : name,
            },
            'on_list' : [ 'id' ]
          }

          dbw.insert_update_dict(d)

    return self

  #  calls:
  #     sec_key
  #       sec_process
  #       sec_file2db
  def sec_author_add(self, ref = {}):
    self.sec_key('add','author_id',ref)

    return self

  def sec_author_rm(self, ref = {}):
    self.sec_key('rm','author_id',ref)

    return self

  def sec_tags_add(self, ref = {}):
    self.sec_key('add','tags',ref)

    return self

  def sec_tags_rm(self, ref = {}):
    self.sec_key('rm','tags',ref)

    return self

  def c_run(self,ref = {}):

    for d_act in self.acts:
      act = d_act
      args = []
      if type(d_act) in [dict]:
        act  = d_act.get('act','')
        args = d_act.get('args',[])

      util.call(self, act, args)

    return self

  def get_opt_apply(self):
    if not self.oa:
      return self

    for k in util.qw('f_yaml'):
      v  = util.get(self,[ 'oa', k ])
      m = re.match(r'^f_(\w+)$', k)
      if m:
        ftype = m.group(1)
        self.files.update({ ftype : v })

    for k in util.qw('act'):
      v  = util.get(self,[ 'oa', k ])
      if v:
        acts = string.split_n_trim(v, sep = ',' )
        for act in acts:
          self.acts.append({ 'act' : act })

    for k in util.qw('sec'):
      setattr(self, k, getattr(self.oa, k))

    return self

  def get_opt(self):
    if self.skip_get_opt:
      return self

    mixGetOpt.get_opt(self)

    self.get_opt_apply()

    return self

  def main(self):

    acts = [
      [ 'get_opt' ],
      [ 'load_yaml' ],
      [ 'do_cmd' ],
    ]

    util.call(self,acts)
