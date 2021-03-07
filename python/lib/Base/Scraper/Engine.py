
import requests
from bs4 import BeautifulSoup, Comment

import getopt,argparse
import sys,os,stat
import yaml
import re
import json

from tabulate import tabulate
from requests_html import HTMLSession


import datetime
#from cdata.core import any2utf8

import sqlite3
import sqlparse

from rdflib import Graph, plugin
from rdflib.serializer import Serializer

import html.parser
import html

import lxml

import base64
from pathlib import Path

from urllib.parse import urlparse
from urllib.parse import urljoin

from url_normalize import url_normalize
from copy import copy


from io import StringIO

from npm.bindings import npm_run
from npm.bindings import npm_install

#from jinja2 import Template

import jinja2
import shutil
import filecmp

import cyrtranslit

import os,sys

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

from Base.Zlan import Zlan
from Base.Core import CoreClass
from Base.Scraper.Server import Srv
from Base.Scraper.Pic import Pic

from http.server import BaseHTTPRequestHandler, HTTPServer
import time


class dbFile(CoreClass):
  images = None
  pages = None

class mixCmdRunner:

  def do_cmd(self,cmds=None):
    if not cmds:
      cmds = util.get(self,'vars.mixCmdRunner.cmds',[])

    for cmd in cmds:
      sub = f'c_{cmd}'
      if not util.obj_has_method(self,sub):
        print(f'No method: {sub}')
        continue

      util.call(self, sub)
  
    return self

class mixLogger:

  def die(self,msg='',opts = {}):
    self.log(msg)

    if opts.get('on_fail',1):
      self.on_fail()

    raise Exception(msg)    

    return self

  def log_short(self,msg=[]):
    self.log(msg,{ 'log_ids' : 'log_short' })
    return self

  def log(self,msg=[],opts={}):
    if type(msg) is list:
      for m in msg:
        self.log(m)
      return self
  
    if not type(msg) is str:
      return self
      
    self.log_db(msg)

    log_ids = util.qw('log')
    log_ids_in = opts.get('log_ids',log_ids) 
    if type(log_ids_in) is str:
      log_ids = util.qw(log_ids_in)

    print(msg)

    for lid in log_ids:
      f_log = self._file(lid)
      if f_log:
        with open(f_log, 'a') as f:
          f.write(msg + '\n')
    
    return self

  def log_db(self,msg=[]):
    if type(msg) is list:
      for m in msg:
        self.log(m)
      return self
  
    if not type(msg) is str:
      return self

    db_file = self.dbfile.pages
    conn = sqlite3.connect(db_file)
    c = conn.cursor()
  
    insert = {
        'msg'   : msg,
        'rid'   : self.page.rid,
        'url'   : self.page.url,
        'site'  : self.page.site,
        'time'  : util.now()
    }
  
    d = {
       'db_file' : self.dbfile.pages,
       'table'   : 'log',
       'insert'  : insert,
    }
    dbw.insert_dict(d)

    return self

class Page(CoreClass):

  app     = None
  baseurl = None
  host    = None
  rid     = None
  site    = None
  url     = None
  url_srv = None

  pics    = []

  ii_full = None
  tags    = None

  def __init__(page,ref={}):
    super().__init__(ref)

  def dict(page):
    data = {}
    for k in dir(page):
      if k in [ '__dict__', '__module__' ]:
        continue

      v = getattr(page,k)
      if type(v) in [ dict,list,str,int ]:
        data.update({ k : v })

    return data
      
  # depth of link following
  depth     = 0

  pass


class BS(CoreClass,mixLogger,mixCmdRunner):
  # class attributes {
  usage='''
  PURPOSE
        This script will parse input URL
  EXAMPLES
        bs.py -y mix.yaml -p list_sites
        bs.py -c db_fill_tags
'''

  html_parser = html.parser.HTMLParser()

  # data
  data = {}

  ext_dir_pieces = {
     'mjs' : 'js'
  }

  asset_exts = util.qw('js css')

  # global variables
  globals = {}

  # loaded python modules
  modules = { 
    'sites' : {}
  }

  # current page's base URL
  base_url = None

  vars = {
    'mixCmdRunner' : {
      'cmds' : []
    }
  }

  # current HTML content
  content = None

  # need to run npm? see init_npm(), init_npm_run()
  wp_run = None

  # directories
  dirs = {}

  # sqlite table columns, e.g. pages, imgs
  cols = {}

  # files
  files = {}

  # code, e.g. html, tex
  code = {
    'tex' : None,
    'html' : None,
  }

  # input directory
  in_dir = os.path.join(os.getcwd(),'in')

  # input YAML file
  f_yaml = None

  # output directory
  out_dir = None

  #command-line options
  oa = None

  # pages - stored info about processed urls
  pages = []

  # current page data
  page = Page({})

  # beautiful soup instance for the current page
  soup = None

  # soups
  soups = {}

  # site-specific data
  sites = {}

  # Page class instance from loaded site module
  page_parser = None

  # tex lines
  tex_lines = []

  # current image data
  pic = Pic()

  skip_get_opt = False

  # list of databases
  dbfile = dbFile()

  # list of urls to be fetched and parsed
  urldata = []

  bin_subpaths = {
    'js' : 'src',
    'mjs' : 'src',
  }

  # end: attributes }

  def __init__(self,args={}):
    self.img_root = os.environ.get('IMG_ROOT')
    self.html_root = os.environ.get('HTML_ROOT')

    for k, v in args.items():
      setattr(self, k, v)

    for k in util.qw('img_root html_root'):
      self.dirs[k] = util.get(self,k) 

    if (not self.dbfile.images) and self.img_root:
      self.dbfile.images = os.path.join(self.img_root,'img.db')

    if (not self.dbfile.pages) and self.html_root:
      self.dbfile.pages = os.path.join(self.html_root,'h.db')

    self.cols['pages'] = dbw._cols({
      'db_file' : self.dbfile.pages,
      'table'   : 'pages',
    })

  def get_opt(self):
    if self.skip_get_opt:
      return self

    self.parser = argparse.ArgumentParser(usage=self.usage)
    
    self.parser.add_argument("-y", "--f_yaml", help="input YAML file",default="")
    self.parser.add_argument("-z", "--f_zlan", help="input ZLAN file",default="")

    self.parser.add_argument("-i", "--f_input_html", help="input HTML file",default="")
    self.parser.add_argument("-f", "--find", help="Find elements via XPATH/CSS",default="")

    self.parser.add_argument("-g", "--grep", help="Grep in input file(s)",default="")
    self.parser.add_argument("--gs", help="Grep scope",default=10)

    self.parser.add_argument("-p", "--print", help="Print field value and exit",default="")

    self.parser.add_argument("-c", "--cmd", help="Run command(s)")
    
    self.oa = self.parser.parse_args()

    if len(sys.argv) == 1:
      self.parser.print_help()
      sys.exit()

    for k in util.qw('f_yaml f_zlan f_input_html'):
      v  = util.get(self,[ 'oa', k ])
      m = re.match(r'^f_(\w+)$', k)
      if m:
        ftype = m.group(1)
        self.files.update({ ftype : v })

    cmd_s = util.get(self,'oa.cmd')
    if not cmd_s:
      print('No command provided!')
      exit(0)

    cmds = cmd_s.split(',')
    self.vars['mixCmdRunner']['cmds'].extend(cmds)

    return self

  def print_field(self):

    pfield = util.get(self,'oa.print','')
    if not pfield:
      return self

    val = util.get(self,pfield,None)
    if val != None:
      val_type = util.var_type(val)
      print(f'print_field {pfield} {val_type}')
      if val_type == 'list':
        for a in val:
          print(a)

###ih
  def input_html_process(self):

    fih = self.files.get('input_html')
    if not ( fih and os.path.isfile(fih) ):
      return self

    fih = os.path.abspath(fih)
    cnt = None
    with open(fih,'r') as f:
      cnt = f.read()

    bs = BeautifulSoup(cnt,'html5lib')
    self.soups[fih] = bs

###find
    find  = util.get(self,'oa.find')
    if find:
      els = bs.select(find)
      print(els)

###grep
    grep  = util.get(self,'oa.grep')
    scope = util.get(self,'oa.gs',10)
    scope = int(scope)

    if grep:
      found = []

      lines = cnt.split('\n')
      lines_dict = {}

      lnums = []
      ln = 1
      for line in lines:
        lnums.append(ln)

        lines_dict[ln] = line
        ln += 1

      for ln in lnums:
        line = lines_dict.get(ln)
        if re.search(rf'{grep}',line):
          found.append([ ln, line ])

          found_j = []
          for lj in range( ln - scope, ln + scope ):
            line_j = lines_dict.get(lj)
            sign = ''
            if lj == ln:
              sign = '=>'

            found_j.append([ lj, sign, line_j ])

          t = tabulate(found_j,headers = util.qw('N F L'))
          print(t)

      if len(found):
        t = tabulate(found,headers = util.qw('N L'))
        print(t)

    find = util.get(self,'oa.find')

    exit(0)

  def init_tmpl(self):
    self.template_loader = jinja2.FileSystemLoader(searchpath=self._dir('tmpl'))
    env  = jinja2.Environment(loader=self.template_loader)
    env.globals['url_join'] = util.url_join

    self.template_env = env

    return self

  def init_db_images(self):
    self.log('[init_db_images]')

    sql = '''
        CREATE TABLE IF NOT EXISTS imgs (
                caption TEXT,
                ext TEXT,
                height integer, 
                img TEXT,
                inum INTEGER,
                name TEXT,
                proj TEXT,
                rootid TEXT,
                sec TEXT,
                tags TEXT,
                type TEXT, 
                url TEXT UNIQUE,
                url_parent text, 
                width integer,
                md5 TEXT UNIQUE
        )
    '''

    dbw.sql_do({ 
      'sql'     : sql,
      'db_file' : self.dbfile.images
    })

    return self

###db
###db_init
  def init_db_pages(self):
    self.log('[init_db_pages]')
  
    sql = '''

            DROP TABLE IF EXISTS log;
            DROP TABLE IF EXISTS tags;
            -- DROP TABLE IF EXISTS page_tags;

            CREATE TABLE IF NOT EXISTS data_meta (
                rid INTEGER UNIQUE,
                url TEXT UNIQUE NOT NULL,
                src TEXT,
                og_url TEXT
            );

            CREATE TABLE IF NOT EXISTS pages (
                baseurl TEXT,
                host TEXT,
                rid INTEGER UNIQUE,
                url TEXT UNIQUE NOT NULL,
                date TEXT,
                title TEXT,
                title_h TEXT,
                site TEXT,
                ii TEXT,
                ii_num INTEGER,
                ii_full TEXT,
                author_id TEXT,
                author_id_first TEXT,
                author TEXT,
                tags TEXT,
                encoding TEXT,
                ok INTEGER
            );

            CREATE TABLE IF NOT EXISTS page_tags (
                url TEXT,
                rid TEXT,
                tag TEXT,
                FOREIGN KEY (url) REFERENCES pages(url)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS authors (
                id TEXT NOT NULL UNIQUE,
                url TEXT,
                name TEXT
            );

            CREATE TABLE IF NOT EXISTS tag_stats (
                tag TEXT NOT NULL UNIQUE,
                rank INTEGER,
                rids TEXT
            );


            CREATE TABLE IF NOT EXISTS log (
                engine TEXT DEFAULT 'bs',
                rid INTEGER,
                url TEXT,
                site TEXT,
                msg TEXT,
                time TEXT
            );
        '''
    dbw.sql_do({ 
      'sql'     : sql,
      'db_file' : self.dbfile.pages
    })

    return self

###npm
  def init_npm(self):
    f = self._file('package_json.prod')
    if not os.path.isfile(f):
      os.chdir(self._dir('html'))

    os.makedirs(self._dir('html','js dist'), exist_ok=True)

    self.wp_run = False

    self                        \
        .init_npm_cp_vcs_prod() \
        .init_npm_cp_prod_vcs() \
        .init_npm_run()         \

    return self

  # prod => vcs
  def init_npm_cp_prod_vcs(self):
    kk = util.qw('package_json')

    for k in kk:
      w_vcs   = self._file(f'{k}.vcs')
      w_prod  = self._file(f'{k}.prod')

      cp = 1
      if os.path.isfile(w_prod):
        cp = cp and not filecmp.cmp(w_prod,w_vcs)

        if cp: 
          shutil.copy(w_prod, w_vcs)

    return self

  # vcs => prod
  def init_npm_cp_vcs_prod(self):
    kk = util.qw('webpack_config_js')

    for ext in self.asset_exts:
      subpath = self.bin_subpaths.get(ext,'')

      ext_stems = self._bin_ext_stems(ext,subpath)
      kk.extend( list(map(lambda x: f'{x}_{ext}',ext_stems)) )

    for k in kk:
      w_vcs   = self._file(f'{k}.vcs')
      w_prod  = self._file(f'{k}.prod')
  
      cp = 1
      if os.path.isfile(w_prod):
        cp = cp and not filecmp.cmp(w_prod,w_vcs)

      if cp: 
        self.wp_run = True

        pp = Path(w_prod).parent.as_posix()
        os.makedirs(pp,exist_ok=True)
        shutil.copy(w_vcs, w_prod)

    return self

  def init_npm_run(self):
    if not self.wp_run:
      return self

    old = os.getcwd()
    cmd = 'build'
    try:
        self.log(f'[BS][npm_init] running npm command: {cmd}')

        os.chdir(self._dir('html'))

        stderr, stdout = npm_run('run',cmd)

        if len(stderr):
          print(stderr)
          raise
    except:
        self.log(f'[BS][npm_init] failure while npm_run("{cmd}")')
    finally:
        os.chdir(old)

    return self

  def init_files(self):

    for lid in util.qw('log log_short log_need'):
      f_log = self._dir('out',f'{lid}.txt')

      self.files.update({ 
          lid : f_log,
      })

      if os.path.isfile(f_log):
        Path(f_log).unlink()

    self.files.update({ 
        'package_json.prod'      : self._dir('html','package.json'),
        'package_json.vcs'       : self._dir('bin','js package.json'),
        'webpack_config_js.vcs'  : self._dir('bin','js webpack.config.js'),
        'webpack_config_js.prod' : self._dir('html','webpack.config.js'),
    })

    for ext in self.asset_exts:
      subpath = self.bin_subpaths.get(ext,'')

      ext_dir = self.ext_dir_pieces.get(ext,ext)

      for stem in self._bin_ext_stems(ext,subpath):

        rel = f'{ext_dir} {subpath} {stem}.{ext}'
        self.files.update({ 
            f'{stem}_{ext}.vcs'  : self._dir('bin',rel),
            f'{stem}_{ext}.prod' : self._dir('html',rel),
        })
  
    self.files.update({ 
        'bundle_js.dist'    : self._dir('html','js dist bundle.js'),
        'bundle_js.final'   : self._dir('html_root','bs dist bundle.js'),
    })

    return self


  def _bin_ext_stems(self,ext=None,subpath=None):
    if not ext:
     return []

    ext_stems = list(map(lambda x: Path(x).stem,self._bin_ext_files(ext,subpath) ))

    return ext_stems

  def _bin_ext_files(self,ext=None,subpath=''):
    if not ext:
     return []

    ext_dir = self.ext_dir_pieces.get(ext,ext)

    ext_files = list(Path(self._dir('bin',f'{ext_dir} {subpath}')).glob(f'*.{ext}'))
    ext_files = list(map(lambda x: x.as_posix(),ext_files))

    return ext_files

  def init_dirs_f_yaml(self):

    f_yaml = self._file('yaml')

    if not f_yaml:
      return self

    pp = Path(f_yaml).resolve()
    dir = str(pp.parent)
    stem = pp.stem

    self.dirs.update({
        'bin_yaml'      : dir,
    })

    self.dirs.update({
        'out'      : os.path.join(dir,'out',stem),
        'in'       : os.path.join(dir,'in'),
        'in_sites' : os.path.join(dir,'in','sites'),
    })

    return self

  def init_df_script_bin(self):
    if not self._file('script'):
      self.files.update({
          'script' : os.path.realpath(__file__),
      })
    self.log(f'[BS] Script location: {self._file("script")}')

    if not self._dir('bin'):
      self.dirs.update({
          'bin' : str(Path(self._file('script')).parent),
      })

    return self

  def init_dirs(self):
    self.init_df_script_bin()
    
    if not util.get(self,'dirs.tmpl'):
      self.dirs['tmpl'] = os.path.join(self._dir('bin'),'tmpl')
    self.log(f'[BS] Template directory: {self._dir("tmpl")}')

    self.init_dirs_f_yaml()
    
    self.dirs.update({ 
      'html'       : self._dir('out' , 'html'),
      'tex_out'    : self._dir('out' , 'tex'),
      'tmp_img'    : self._dir('img_root', 'tmp' ),
    })

    return self

  def mk_dirs(self):
    for k,v in self.dirs.items():
      os.makedirs(v, exist_ok=True)

    return self

  def _yaml_data(self, f_yaml=None):
    if not f_yaml:
      f_yaml = self._file('yaml')

    if f_yaml and os.path.isfile(f_yaml):
      with open(f_yaml) as f:
        d = yaml.full_load(f)
        return d

    return 

  def dbg_load_zlan(self, ref={}):
   for url in zorder:
      d = zdata.get(url)
      tags = d.get('tags','')
      redo = d.get('redo','')
      acts = d.get('acts',[])

      print(f'*'*50)
      print(f'tags => {tags}')
      print(f'redo => {redo}')
      print(f'acts => {acts}')

   print(f'zorder => {len(zorder)}')
   print(f'd_global => {z.d_global}')

   return self

###zlan
  def load_zlan(self, ref={}):
    f_zlan = util.get(self,'files.zlan')
    f_zlan = ref.get('zlan',f_zlan)

    if not f_zlan:
      return self

    z = Zlan({})

    z.get_data({ 'file' : f_zlan })

    zdata = z.data
    zorder = z.order

    if not self.urldata:
      self.urldata = []

    for k in zdata.keys():
      if k in util.qw('order lines_main lines_eof'):
        continue
        
      url = k
      d = zdata.get(url)
      if not d.get('off'):
        self.urldata.append(d)

    return self

  def load_yaml(self, f_yaml=None):
    if not f_yaml:
      f_yaml = self._file('yaml')

    if f_yaml and os.path.isfile(f_yaml):
      with open(f_yaml) as f:
        d = yaml.full_load(f)
        for k,v in d.items():
          setattr(self,k,v)

    if os.path.isdir(self.in_dir):
      for f in Path(self.in_dir).glob('*.yaml'):
        k = Path(f).stem
        with open(str(f),'r') as y:
          d = yaml.full_load(y)
          setattr(self, k, d)

    return self

# True if left.mtime > right.mtime, i.e. 'left' is more recent that 'right'
  def _file_mtime_gt(self, left, right):
    return ( self._file_mtime(left) > self._file_mtime(right) )

  def _file_mtime(self, id):
    f = self._file(id)

    if not self._file_exist(id):
      return 0 

    mt = os.stat(f).st_mtime
    mt = int(mt)
    return mt

  def _file_exist(self, id):
    f = self._file(id)

    ok = True if (f and os.path.isfile(f)) else False
    return ok

  def _file(self, id):

    f = util.get(self,[ 'files' , id ])
    return f

  # self._dir({ obj = 'out.tmpl', fs = '' })
  # self._dir('out.tmpl')
  # self._dir('img_root','tmp')
  def _dir(self, arg = {}, *args):

    dir      = None
    path_fs  = []
    path_obj = []

    if type(arg) is dict:
      path_obj = util.get(arg,'obj',[])
      path_fs  = util.get(arg,'fs',[])

    elif type(arg) is str:
      path_obj = arg
      if args:
        if type(args[0]) is str:
          path_fs = args[0].split(' ')
        elif type(args[0]) is list:
          path_fs = args[0]

    if path_obj:
      if type(path_obj) is str:
        z = path_obj.split(' ')
        dir = util.get(self.dirs,z.pop(0))
        if len(z):
          path_fs = z + path_fs

      elif type(path_obj) is list:
        dir = util.get(self.dirs,path_obj)

    if dir:
      a = [ dir ]
      if path_fs:
        a.extend(path_fs)
        dir = str(Path(*a))

    
    return dir

  def _dir_ii(self,ref={}):
    rid = ref.get('rid',self.page.rid)

    #dir = os.path.join(self.html_root,'bs',str(rid))
    dir = self._dir('html_root',f'bs {rid}')

    return dir

  def _dir_ii_img(self):
    img_dir = os.path.join(self._dir_ii(),'img')
    if not os.path.isdir(img_dir):
      os.makedirs(img_dir,exist_ok=True)
    return img_dir

  def _file_rid_uri(self,ref={}):
    ii_file = self._file_rid(ref)
    uri = Path(ii_file).as_uri()
    return uri

  def _file_rid(self,ref={}):
    tipe = ref.get('tipe','cache')
    ext  = ref.get('ext','html')
    rid  = ref.get('rid',self.page.rid)

    ii_file = os.path.join(self._dir_ii({ 'rid' : rid }),f'{tipe}.{ext}')
    return ii_file

  def _need_process(self,ref={}):

    dw  = self._db_urlpage()
    dwr = dw.get('row',{}) if dw else {}

    need = True

    ok_db = None
    date_db = None

    while 1:
      if self._site_skip():
        need = False
        break
  
      if ref.get('redo',0):
        need = True
        break
  
      if dwr:
        ok_db = dwr.get('ok')
  
        if not ( ok_db == None ):
          if ok_db == 0:
             need = True
             self.page.listadd('acts','db_update')
             break
    
        if not self._opt('no_date'):
          date_db = dwr.get('date')
          if not date_db:
            need = True
            self.page.listadd('acts','db_update')
            break

      need = need and not self._url_saved_fs() 

      break

    #if need:
      #self.log(f'date_db: {date_db}, ok_db: {ok_db}, url: {self.page.url}', { 'log_ids' : 'log_need' })

    #self.log_short(f'rid: {self.page.rid}, need: {need}, url: {self.page.url}')

    return need

  def _need_load_cache(self):
    #ok = 1 if not self._act('fetch')  \
      #and self.page.mode == 'saved' \
      #and os.path.isfile(self.ii_cache) else 0
    ok = not self._act('fetch')
    ok = ok and self.page.mode == 'saved'
    ok = ok and os.path.isfile(self.ii_cache)

    return ok

  def url_load_content(self,ref={}):
    if self._need_load_cache():
       with open(self.ii_cache,'r') as f:
           self.content = f.read()
           return self

    self.url_fetch()

    return self

  def url_fetch(self,ref={}):
    url = ref.get('url',self.page.url)

    self.log(f'[url_fetch] fetching url: {url}')

    if self.page.get('fetched'):
      return self

    headers = {}
    headers = {
     'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.3'
    }

    tries = util.qw('requests requests_html')
    tries = util.qw('requests')
    url_fetch_mode = ref.get('url_fetch_mode','requests')

    ok = 1
    r = None
    for tri in tries:
      if tri == 'requests':
        try:
          r = requests.get(url,headers=headers)
        except:
          ok = 0

        ok = r.ok

      elif tri == 'requests_html':
        session = HTMLSession()
        r = session.get(url)

      if not ok:
        self.die(f'ERROR[url_fetch] url: {url}')
      else:
        break

    encoding = 'utf-8'

    ct = r.headers.get('content-type', '').lower()
    setattr(self.page, 'ct', ct)

    if 'charset' in self.page.ct:
      encoding = r.encoding
    self.page.encoding = encoding

    self.content = r.content
    bs = BeautifulSoup(self.content,'html5lib',from_encoding=encoding)
    self.content = bs.prettify()

    self.page_save_cache()

    self.page.set({ 'fetched' : 1 })

    return self

  def page_save_cache(self):

    util.mk_parent_dir(self.ii_cache)

    with open(self.ii_cache, 'w') as f:
      f.write(self.content)

    return self

  def load_soup_file_rid(self,ref={}):
    tipe = ref.get('tipe','cache')
    ext  = ref.get('ext','html')

    rid = self.page.rid

    tipes_in = ref.get('tipes')
    if tipes_in:
      tipes    = tipes_in
      if type(tipes_in) is str:
        tipes = tipes_in.split(',') 
  
      if len(tipes):
        del ref['tipes']
        for tipe in tipes:
          r = copy(ref)
          r['tipe'] = tipe
          self.load_soup_file_rid(r)
        return self

    self.log(f'[{rid}][load_soup_file_rid] tipe: {tipe}, ext: {ext}')

    file = self._file_rid({ 'tipe' : tipe, 'ext' : ext })

    if os.path.isfile(file):
      with open(file,'r') as f:
        html = f.read()
        self.soups[file] = BeautifulSoup(html,'html5lib')

    return self

  def load_soup(self,ref={}):
    url = ref.get('url',self.page.url)
    ii  = ref.get('ii',self.page.ii)

    self.page.mode = 'saved'

    self.page.rid = self._rid_url(url)

    # page is new
    if not self.page.rid:
      self.page.rid = self._rid_new()
      self.page.mode = 'new'

    self.ii_cache = self._file_rid()
    self.url_load_content()

    self.soup = BeautifulSoup(self.content,'html5lib',from_encoding=self.page.get('encoding'))

    t = self.soup.select_one('head > title').string
    t = util.strip(t)
    self.page.title = t

    h1 = self.soup.select_one('h1')
    title_h = ''
    if h1:
      s = h1.string
      if s:
        title_h =  util.strip(s)
        self.page.set({ 'title_h' : title_h })

    self.log(f'[load_soup] rid: {self.page.rid}, title: {self.page.title}')
    self.log(f'[load_soup] rid: {self.page.rid}, title_h: {title_h}')
    
    return self

  def _sel_clean_core(self):
    clean = []
    clean.extend( util.get(self,'cnf.sel.clean',[]) )

    keep = self._sel_keep()
    for k in keep:
      while k in clean:
        clean.remove(k)

    return clean

  def _sel_keep(self, site=None):
    if not site:
      site = self.page.site

    keep = []
    keep.extend( util.get(self,[ 'sites', site, 'sel', 'keep' ],[]) )
    return keep
     
  def _sel_clean(self, site=None):
    if not site:
      site = self.page.site

    clean = []
    clean.extend( self._sel_clean_core() )

    clean_site = util.get(self,[ 'sites', site, 'sel', 'clean' ],[])
    if clean_site:
      clean.extend( clean_site )
    
    return clean

  def _sel_only(self, site=None):
    if not site:
      site = self.page.site

    only = []

    only_site = util.get(self,[ 'sites', site, 'sel', 'only' ],[])
    if only_site:
      only.extend( only_site )
    
    return only

  def page_clean_core(self):
    clean = self._sel_clean_core()
    self.page_clean({ 'clean' : clean })
    return self

###rm_cmt
  def page_rm_comments(self,ref={}):
    els = self.soup.find_all(text=lambda text:isinstance(text, Comment))
    for e in els:
      if isinstance(e,Comment):
        e.extract()
    return self

  def page_only(self,ref={}):
    site = util.get(self,'site',self.page.site)

    # list
    only = self._sel_only(site)
    only = util.get(ref,'only',only)
    if not (only and len(only)):
      return self

    children = self.soup.body.findChildren(True,recursive=False)

    found = 0
    for css in only:
      els = copy(self.soup.select(css))
      if els and len(els): 
        found = 1
        for el in els:
          self.soup.body.append(el)

    if found:
      for child in children:
         child.decompose()

    return self

  def get_html(self,ref={}):
    rid  = util.get(ref,'rid','')
    tipe = util.get(ref,'tipe','')

    css    = util.get(ref,'css','')
    xpath  = util.get(ref,'xpath','')

    act    = util.get(ref,'act','display')

    file_html = self._file_rid({ 
      'rid'  : rid, 
      'tipe' : tipe, 
      'ext'  : 'html', 
    })

    src_code = ''
    if os.path.isfile(file_html):
      with open(file_html,'r') as f:
        src_code = f.read()

    src_html = src_code

    if css or xpath:
      bs = BeautifulSoup(src_code,'html5lib')
      if css:
        els = bs.select(css)
        if not els:
          return { 'src_code' : '', 'src_html' : ''}

        if act == 'display':
          txt = []
          for el in els:
            txt.append(str(el))
     
          src_code = '\n'.join(txt)
          src_html = '<br>\n'.join(txt)
  
        elif act == 'remove':
          for el in els:
            el.decompose()
  
          src_code = str(bs)
          src_html = src_code

      elif xpath:
        tree =  lxml.html.fromstring(str(bs.html))
        found = tree.xpath(xpath)

        if not found:
          return { 'src_code' : '', 'src_html' : ''}

        if act == 'display':
          txt = []
          for el in found:
            s = lxml.html.tostring(el)
            s = s.decode('utf-8')
            txt.append(s)

          src_code = '\n'.join(txt)
          src_html = '<br>\n'.join(txt)

          #ss = BeautifulSoup(src_code, convertEntities=BeautifulSoup.HTML_ENTITIES)
          #ss = BeautifulSoup(src_code)
          #src_code = str(ss)
          src_code = self.html_parser.unescape(src_code)

        if act == 'remove':
          for el in found:
            el.getparent().remove(el)

    #html = encodeURIComponent(html);

    return { 
        # iframe
        'src_html' : src_html,

        # textarea
        'src_code' : src_code,
    }


  def page_clean(self,ref={}):
    site = util.get(self,'site',self.page.site)

    clean = self._sel_clean(site)
    clean = util.get(ref,'clean',clean)

    for c in clean:
      if c in self._sel_keep(site):
        continue

      els_clean = self.soup.select(c)
      for el in els_clean:
        el.decompose()

    p = self.page_parser
    if p:
      p.clean()

    return self

  def page_header_insert_url(self):
    h = self.soup.select_one('h1,h2,h3,h4,h5,h6')

    if not h:
      return self

    a = self.soup.new_tag('a', )
    a['href'] = self.page.url
    a['target'] = '_blank'
    a.string = self.page.url
    h.insert_after(a)
    a.wrap(self.soup.new_tag('p'))

    return self

  def page_save(self,ref={}):
    tipe = util.get(ref,'tipe','clean')
    ext  = util.get(ref,'ext','html')

    sv = self._file_rid({ 'tipe' : tipe })
    if tipe == 'clean':
       self.ii_clean = sv

    util.mk_parent_dir(sv)

    with open(sv, 'w') as f:
      f.write(self.soup.prettify())

    return self

  def import_data(self,ref={}):
    urldata = util.get(ref,'urldata',[])

    self.parse(urldata)

    return self

  def page_add(self):
    uri_dict = {
        'base'   : self.page.baseurl,
        'url' : self.page.url,
    }

    tipe_map = { 
      'html' : util.qw('log cache core clean img img_clean dbrid'),
      'txt'  : util.qw('meta script'),
    }

    for ext in tipe_map.keys():
      tipes = tipe_map.get(ext,[])
      for tipe in tipes:
        uri_dict.update({ 
          tipe : self._file_rid_uri({ 'tipe' : tipe, 'ext' : ext }),
        })

    self.page.set({
      'uri'   : uri_dict
    })

    if self.page.len():
      self.pages.append(self.page)

    return self

  def fill_vars(self):
    self.fill_list_sites()
    return self

  def fill_list_sites(self):

    hosts = util.get(self,'hosts',[])

    l = [ hosts.get(x).get('site','') for x in hosts.keys() ]
    l = list(filter(lambda x: len(x) > 0,l))
    l = util.uniq(l)
    l.sort()

    self.list_sites = l

    inc = util.get(self,'include.sites',[])
    exc = util.get(self,'exclude.sites',[])

    if len(exc) == 0:
      inc = self.list_sites

    for lst in [ inc, exc ]:
      for i in lst:
        if i == '_all_':
          lst.extend(self.list_sites)
          lst.remove('_all_')

    self.list_sites_inc = inc
    self.list_sites_exc = exc

    return self

  def _site_data(self,path=None,default=None):
    d = None

    site = self.page.site

    if not path:
      return util.get(self,[ 'sites' , site ],default)

    a = [ 'sites', site ]
    if type(path) is str:
      a.extend(path.split('.'))
      d = util.get(self, a, default)

    return d

  def in_load_site_yaml(self,ref={}):
    site = ref.get('site',self.page.site)

    [ lib, mod ] = self._site_libdir(site)
    site_yaml = os.path.join(lib,mod + '.yaml')

    if not os.path.isfile(site_yaml):
      return self

    d = self._yaml_data(site_yaml)
    self.sites[site] = d

    self.log(f'[in_load_site_yaml] loaded YAML for site: {site}' )
    return self

###im
  def in_load_site_module(self,ref={}):
    site = ref.get('site',self.page.site)

    [ lib, mod ] = self._site_libdir(site)

    libs     = [ lib ]

    mod_py   = os.path.join(lib,mod + '.py')
    mod_yaml = os.path.join(lib,mod + '.yaml')

    if not os.path.isdir(lib):
      os.makedirs(lib,exist_ok=True)

    if not os.path.isfile(mod_yaml):
      site_yml = self._dir('bin','yml _site.yaml')
      with open(site_yml,'r') as f:
        yml = f.read()
        with open(mod_yaml, 'w') as f:
            f.write(yml)

    if not os.path.isfile(mod_py):
      site_py = self._dir('bin','py _site_pageparser.py')
      with open(site_py,'r') as f:
        py = f.read()
        with open(mod_py, 'w') as f:
            f.write(py)

    self.site_prepare_init_py()

    if not os.path.isfile(mod_py):
      return self

    # module name
    util.add_libs(libs)
    m = self.modules['sites'][site] = __import__(mod)

    if m:
      self.log(f'[in_load_site_module] loaded module for site: {site}' )
      p = self.page_parser = m.PageParser({ 
        'soup' : self.soup,
        'app'  : self,
      })

    return self

  def site_prepare_init_py(self,site=None):
    if not site:
      site = self.page.site

    inpath = self._dir('in_sites')
    pieces = site.split('.')
    pieces.pop()
    for piece in pieces:
      init_py = os.path.join(inpath,'__init__.py')
      if not os.path.isfile(init_py):
         Path(init_py).touch()

      inpath = os.path.join(inpath,piece)
    return self

###sl
  def page_save_log(self):
    log_file = self._file_rid({ 
      'tipe' : 'log', 
      'ext'  : 'html' 
    })

    q = '''SELECT * FROM log WHERE url = ?'''
    p = [self.page.url]

    dw = dbw.sql_fetchall(q,p,{ 
        'db_file' : self.dbfile.pages
    })
    if not dw:
      return self

    rows = dw.get('rows',[])
    cols = dw.get('cols',[])

    t = self.template_env.get_template("log.t.html")
    h = t.render(rows=rows,cols=cols)

    with open(log_file, 'w') as f:
      f.write(h)

    return self

  def update_ii(self):
    self.page_ii_from_title()
    self.log(f'[load_soup] ii: {self.page.ii}')
    
    return self

  def page_save_data_txt(self):
    tipes = 'meta,script,img,link,head,a,article'

    self.page_save_data({ \
      'tipes' :  tipes    \
    })                    \

    return self

###ld_json
  def page_load_ld_json(self):
    els_jd = self.soup.find_all("script", { "type" : "application/ld+json" })

    j = []
    for e in els_jd:
      try:
        e_data = e.string.split('\n')
        e_data_new = []

        while len(e_data):
          ln = e_data.pop(0).strip()

          if re.match(r'^/\*<!\[CDATA\[\*/$',ln):
            continue
          if re.match(r'^/\*\]\]>\*/$',ln):
            continue
          
          e_data_new.append(ln)

        e_new = '\n'.join(e_data_new)
        ss = e_new

        jj = None
        try:
          ss = str(ss)
          ss = ss.replace('\r\n', '')
          ss = rf'{ss}'
          #ss = self.html_parser.unescape(ss)
          jj = json.loads(ss,strict=False)
        except:
          raise

        if jj:
          if type(jj) is dict:
            j.append(jj)
          elif type(jj) is list:
            j.extend(jj)
        #g = Graph().parse(data=jj)
      except:
        #self.log('WARN[page_load_ld_json] JSON decode errors')
        #self.log(e.string)
        raise
        continue

      #if type(jj) is dict:
        #j.append(jj)
      #elif type(jj) is list:
        #j.extend(jj)

    self.page.set({ 'ld_json' : j })

    if len(j):
      yy = yaml.dump(j,allow_unicode=True)
      yfile = self._file_rid({ 'tipe' : 'ld_json', 'ext' : 'yaml' })
      with open(yfile, 'w') as f:
        f.write(yy)

    return self

###pur
  def parse_url_run(self,ref={}):
    tipes_img = util.qw('img img_clean')

    self                                              \
        .load_soup()                                  \
        .page_save_data_txt()                         \
        .db_save_meta()                               \
        .page_load_ld_json()                          \
        .in_load_site_module()                        \
        .update_ii()                                  \
        .in_load_site_yaml()                          \

    self                                              \
        .page_get_date()                              \
        .page_get_author()                            \
        .page_get_ii_full()                           \
        .db_save_page()                               \
        .cmt(''' save image data => img.html''')      \
        .page_save_data_img()                         \
        .page_clean_core()                            \
        .page_rm_comments()                           \
        .page_save({ 'tipe' : 'core' })               \
        .page_clean()                                 \
        .page_save({ 'tipe' : 'core_clean' })         \
        .page_only()                                  \
        .page_unwrap()                                \
        .page_rm_empty()                              \
        .page_header_insert_url()                     \
        .page_save()                                  \
        .page_save_data_img({ 'tipe' : 'img_clean' }) \
        .page_do_imgs()                               \
        .page_replace_links({                         \
            'act' : 'rel_to_remote'                   \
        })                                            \
        .page_store_links()                           \
        .load_soup_file_rid({                         \
            'tipes' : tipes_img                       \
        })                                            \
        .ii_replace_links({                           \
            'tipes' : tipes_img,                      \
            'act'  : 'remote_to_db',                  \
        })                                            \
        .page_save()                                  \
        .page_add()                                   \
        .page_save_log()                              \
        .page2yaml()                                  \
        .db_ok()                                      \
        .page_save_db_record()                        \
        .page_save_sh()                               \

    return self

  def site_extract(self):
    
    hsts = self.hosts
    try:
      for pat in hsts.keys():
        for k in pat.split(','):
          if self.page.host.find(k) != -1:
            site = util.get(hsts,[ pat, 'site' ]) 
            if site:
              self.page.set({ 'site' : site })
              raise StopIteration
  
    except StopIteration:
      pass
  
    if not self.page.site:
      self.die(f'[WARN] no site for url: {self.page.url}', { 'on_fail' : 0 })
  
    return self

  def page_set_lst(self,ref={}):

    for id in util.qw('acts opts'):
      lst = ref.get(id)
      if lst:
        lst_a = []
        if type(lst) is list:
          lst_a = lst
        elif type(lst) is str:
          lst_a = lst.split(',')
  
        if lst_a:
          self.page.set({ id :  lst_a })

    self.page.set({ 'tags' : ref.get('tags') })

    return self
  
###pu
  def parse_url(self,ref={}):
    url = ref.get('url','')

    if not url or url == const.plh:
      return self

    self.page = Page({ 
        'ok' : 0,
    })

    for k in util.qw('url date tags ii depth'):
      v = ref.get(k,'')
      v = v.strip()
      self.page.set({ k : v })

    d = util.url_parse(self.page.url)

    for k in util.qw('host baseurl'):
      v = d[k]
      v = v.strip()
      self.page.set({ k : v })

    try:
      self.site_extract()
    except:
      return self

    self.page_set_lst(ref)

    if not self._need_process(ref):
      return self

    self.log(f'[site_extract] site = {self.page.site}')

    self.log('=' * 100)
    self.log(f'[parse_url] start: {self.page.url}')

    self.parse_url_run()

    return self

  def page_ii_from_title(self,ref={}):
    p = self.page_parser

    if self.page.ii:
      return self

    if util.obj_has_method(p, 'generate_ii'):
      p.generate_ii()
    else:
      if self.page.title:
        tt = self.page.title
        tt = re.sub(r'\s', '_', tt)
        ttl = cyrtranslit.to_latin(tt,'ru').lower()
        ttl = re.sub(r'[\W\']+', '', ttl)
        self.page.ii = ttl

    return self

  def page_get_ii_full(self,ref={}):
    self.page.set({ 'ii_full' : self._ii_full() })
    return self

  def page_get_author(self,ref={}):
    p = self.page_parser
    if not p:
      return self

    p.get_author()

    aid = self.page.get('author_id','')
    if not aid:
      #self.die(f'[page_get_author] no author!')
      self.log(f'[page_get_author] no author!')
      return self

    self.log(f'[page_get_author] got author(s): {aid}')

    f = aid.split(',')
    if f and len(f):
       self.page.set({ 'author_id_first' : f[0] })

    return self

  def page_get_date(self,ref={}):
    p = self.page_parser
    if not p:
      return self

    p.get_date()
    date = util.get(self,'page.date')

    if not date:
      if not self._opt('no_date'):
        try:
          raise Exception
        except:
          self.die(f'ERROR[page_get_date] NO DATE: rid: {self.page.rid}, site: {self.page.site}, url: {self.page.url}')
        finally:
          self.on_fail()
    else:
      self.log(f'[page_get_date] got date: {date}')

      fmt = '%d_%m_%Y'
      d = datetime.datetime.strptime(date,fmt)
  
      dd = { 
          'day'   : d.day,
          'year'  : d.year,
          'month' : d.month,
      }
  
      self.page.set(dd)
    #date = d.strftime()

    return self

  def page2yaml(self):

    dy = yaml.dump(self.page.__dict__, allow_unicode=True)
    yfile = self._file_rid({ 'tipe' : 'page', 'ext' : 'yaml' })
    util.mk_dirname(yfile)

    with open(yfile, 'w') as f:
      f.write(dy)

    return self

  def on_fail(self):

    self                           \
        .db_save_page({ 'ok' : 0 }) \
        .page_save_sh()            \
        .page_save_db_record()     \
        .page2yaml()               \

    return self

  def page_rm_empty(self):
    skip_empty = util.qw('img br')

    all = self.soup.find_all(True)
    while 1:
      if not len(all):
        break

      el = all.pop(0)
      if el.name in skip_empty:
        continue

      if len(el.get_text(strip=True)) == 0:
        j = el.find('img')
        if not j:
          el.decompose()
    return self

###js
  def ii_insert_js_css(self,ref={}):
    tipe = ref.get('tipe','cache')
    ext  = ref.get('ext','html')

    tipes_in = self._cnf('BS.ii_insert_js_css.tipes',[])
    tipes_in = ref.get('tipes',tipes_in)

    rid = self.page.rid

    if not len(tipes_in):
      if not tipe:
        return self
      tipes_in = [ tipe ]

    if tipes_in:
      tipes    = tipes_in
      if type(tipes_in) is str:
        tipes = tipes_in.split(',') 
  
      if not len(tipes):
        return self

      for tipe in tipes:

        self.log(f'[{rid}][ii_insert_js_css] {tipe}')
      
        svf = self._file_rid({ 'tipe' : tipe, 'ext' : ext })
        self.load_soup_file_rid({                           \
            'tipe' : tipe,
            'ext'  : ext,
        })
        ii_soup = self.soups.get(svf)
        if not svf:
          continue

        body = ii_soup.body
        script = ii_soup.new_tag('script')
      
        #script['src'] = os.path.relpath(self._file('bundle_js.dist'),self._dir_ii())
        #body.append(script)
      
        #with open(svf, 'w') as f:
          #f.write(ii_soup.prettify())

    return self

  def ii_replace_links(self,ref={}):
    tipe = ref.get('tipe','cache')
    ext  = ref.get('ext','html')
    act  = ref.get('act','rel_to_remote')

    rid = self.page.rid

    tipes_in = ref.get('tipes')
    if tipes_in:
      tipes    = tipes_in
      if type(tipes_in) is str:
        tipes = tipes_in.split(',') 
  
      if len(tipes):
        del ref['tipes']
        for tipe in tipes:
          r = copy(ref)
          r['tipe'] = tipe
          self.ii_replace_links(r)
        return self

    self.log(f'[{rid}][ii_replace_links] {tipe}')

    file = self._file_rid({ 
      'tipe' : tipe, 
      'ext'  : ext 
    })
    soup = self.soups.get(file)

    if soup:
      self.page_replace_links({ 
        'soup' : soup, 
        'act'  : act  
      })
      with open(file, 'w') as f:
        f.write(soup.prettify())

    return self

  def page_store_links(self,ref={}):
    soup = ref.get('soup',self.soup)

    links_site = []
    els = soup.select('a')
    for el in els:
      txt = el.get_text()
      txt = string.strip_n(txt)
      if el.has_attr('href'):
        href = el['href']
        if href == self.page.url:
          continue

        u = util.url_parse(href)
        d_href = { 'txt' : txt, 'href' : href }
        if u['netloc'] == self.page.host:
          links_site.append(d_href)

    self.page.set({ 
        'links' : {
            'site' : links_site 
        } 
    })

    return self

  def page_replace_links(self,ref={}):
    soup = ref.get('soup',self.soup)
    act  = ref.get('act','rel_to_remote')

    j=0

    next = soup.html
    while 1:
      if not next:
        break 
      j+=1
      next = next.find_next()
      if hasattr(next,'name') and next.name == 'a':
        if next.has_attr('href'):
          href = next['href']

          if act == 'rel_to_remote':
            u = util.url_parse(href)
            if not u['netloc']:
              href = util.url_join(self.page.baseurl,href)
              next['href'] = href
            next['target'] = '_blank'

          elif act == 'remote_to_db':
            pic = Pic({ 
              'app' : self,
              'url' : href,
            })
            uri_local = pic.path_uri_srv
            if uri_local:
              next['href'] = uri_local
              next['class'] = 'link uri_local'

    return self

  def page_unwrap(self):
    self.log(f'[page_unwrap] start')

    while 1:
      div = self.soup.select_one('div')
      if not div:
        break
      div.unwrap()

    return self

  def _rid_new(self):
    db_file = self.dbfile.pages
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    q = '''SELECT MAX(rid) FROM pages'''
    c.execute(q)
    rw = c.fetchone()
    rid = rw[0]
    if rid == None:
      rid = 0

    rid += 1

    conn.commit()
    conn.close()

    return rid

  def _db_urlpage(self, ref={}):
    url = ref.get('url')

    if not url:
      url = self.page.url

    q = '''SELECT * FROM pages WHERE url = ?'''
    p = [ url ]
    dw = dbw.sql_fetchone(q,p,{ 
      'db_file' : self.dbfile.pages 
    })

    return dw 

  def _rid_last(self, ref={}):
    db_file = self.dbfile.pages

    q = 'SELECT MAX(rid) FROM pages'
    p = []
    lst = dbw.sql_fetchone_list(q,p,{
      'db_file' : db_file,
    })
    last = lst.pop(0)

    return last

  def _db_get_authors(self, ref={}):
    where = ref.get('where',{})

    db_file = self.dbfile.pages

    q = 'SELECT * FROM authors'
    p = []
    r = dbw.sql_fetchall(q,p,{
      'db_file' : db_file,
      'where'   : where,
    })

    authors = r.get('rows',[])
    cols    = r.get('cols',[])

    r = { 
      'authors' : authors,
      'cols'    : cols,
      'count'   : len(authors),
    }

    return r

  def _render(self, tmpl=''):
    t = self.template_env.get_template(tmpl)
    h = t.render()
    return h

  def _db_tag_urls(self, ref={}):
    tags   = ref.get('tags','')
    tags_a = tags.split(',')

    db_file = self.dbfile.pages

    q = 'SELECT url FROM page_tags'

    urls_a = None

    while tags_a:
      tag = tags_a.pop(0)

      urls_db = dbw.sql_fetchlist(q,[],{
        'db_file' : db_file,
        'where'   : { 
          'tag' : tag,
        }
      })

      urls_f = []
      for url in urls_db:
        if urls_a and (url in urls_a):
          urls_f.append(url)

      urls_a = urls_f

    return urls

  def _db_get_pages(self, ref={}):
    where = ref.get('where',{})

    db_file = self.dbfile.pages

    q = 'SELECT * FROM pages'
    p = []

    urls = []
    if 'tags' in where.keys():
      tags = where.get('tags','')
      urls = self._db_tag_urls({ 'tags' : tags })

      del where['tags']

    r = dbw.sql_fetchall(q,p,{
      'db_file' : db_file,
      'where'   : where,
    })

    rows = r.get('rows',[])
    cols = r.get('cols',[])

    pages = []
    if len(urls):
      for rh in rows:
        url = rh.get('url','')
        if not url in urls:
          continue

        pages.append(rh)
    
    r = { 
      'pages' : pages,
      'cols'  : cols,
      'count' : len(pages),
    }

    return r

  def _db_get_auth(self, ref={}):
    auth_id = ref.get('auth_id')
    if not auth_id:
      return

    auth = None

    db_file = self.dbfile.pages
    conn = sqlite3.connect(db_file)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()

    q = '''SELECT id, name, url FROM authors WHERE id = ?'''
    c.execute(q,[auth_id])
    rw = c.fetchone()
    if rw:
      auth = {}
      for k in rw.keys():
        auth[k] = rw[k]

    conn.commit()
    conn.close()

    return auth

  def db_save_meta(self):
    db_file = self.dbfile.pages

    insert = {
      'url' : self.page.url,
      'rid' : self.page.rid,
    }

    self.page.meta = {}

    r = { 'tipe' : 'meta', 'ext' : 'txt' }
    self.load_soup_file_rid(r)
    f_meta = self._file_rid(r)

    soup = self.soups[f_meta]

    els = soup.find_all(True)
    for el in els:
      if el.has_attr('property'):
        prop = el['property']
        if prop == 'og:url':
          og_url = el['content']
          if og_url:
            i = { 'og_url' : og_url }
            self.page.meta.update(i)
            insert.update(i)

    d = {
      'db_file' : self.dbfile.pages,
      'table'   : 'data_meta',
      'insert'  : insert,
    }

    dbw.insert_dict(d)

    return self

  # update 'page_tags' table from the 'pages' table
  def c_db_fill_tags(self):
    db_file = self.dbfile.pages

    r = dbw.sql_fetchall(
        'SELECT rid,url,tags FROM pages',[],
        { 'db_file' : db_file }
    )
    rows = r.get('rows',[])

    for rh in rows:
      self.db_save_tags(rh)

    return self

  def c_html_parse(self):

    self                    \
      .input_html_process() \

    return self

  def c_srv_start(self):
#    self.srv = Srv({ 
      #'engine' : self 
    #})
    #self.srv.start()

    host_name = "localhost"
    server_port = 8080

    web_srv = HTTPServer((host_name, server_port), Srv)
    print("Server started http://%s:%s" % (host_name, server_port))

    try:
        web_srv.serve_forever()
    except KeyboardInterrupt:
        pass

    web_srv.server_close()
    print("Server stopped.")

    return self

  def c_print_field(self):
    self                    \
      .init()               \
      .fill_vars()          \
      .print_field()        \

    return self

  def c_init_bs(self):
    self                    \
      .init()               \
      .fill_vars()          \

    return self

  def c_run(self):

    self                    \
      .c_init_bs()          \
      .parse()              \
      .render_page_list()   \

    return self

  def db_ok(self):

    dbw.update_dict({
      'db_file'  : self.dbfile.pages,
      'table'    : 'pages',
      'where'    : { 'url' : self.page.url },
      'update'   :  { 'ok' : 1 },
    })

    return self

  def db_save_tags(self,ref = {}):
    tags = ref.get('tags',self.page.tags)
    url  = ref.get('url',self.page.url)
    rid  = ref.get('rid',self.page.rid)

    db_file = self.dbfile.pages

    if not tags:
      return self

    tags_db = dbw.sql_fetchlist(
       'SELECT tag FROM page_tags where url = ?',
       [url],
       { 'db_file' : db_file }
    )

    tags_a = tags.split(',')

    for tag in tags_a:
      if tag in tags_db:
        continue

      ins_tags = {
        'rid' : rid,
        'url' : url,
        'tag' : tag,
      }
      d = {
        'db_file' : db_file,
        'table'   : 'page_tags',
        'insert'  : ins_tags,
      }
      dbw.insert_dict(d)

    return self

###db_save
# self.page => pages table 
# self.page.tags => page_tags table
#   see: db_save_tags()
  def db_save_page(self,ins = {}):

    db_file = self.dbfile.pages
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    rid = self._rid_url()
    if not rid:
      rid = self._rid_new()

    self.page.rid = rid 

    if not len(ins):
      if self._url_saved_db():
        if not self._act('db_update'):
          return self

    insert = {
      'url' : self.page.url,
    }
    insert.update(ins)
    self.page.set(ins)

    cols = dbw._cols({
        'db_file' : self.dbfile.pages,
        'table'   : 'pages',
    })

    for k in self.page.__dict__.keys():
      if not k in cols:
        continue

      v = self.page.get(k)
      if type(v) is str or type(v) is int:
        insert.update({ k : v })

    d = {
      'db_file' : self.dbfile.pages,
      'table'   : 'pages',
      'insert'  : insert,
    }
    dbw.insert_dict(d)

    self.db_save_tags()
    
    self.log(f'[db_save_page] url saved with rid {self.page.rid}')

    return self

  def _site_libdir(self,site=None):
    if not site:
      site = self.page.site

    a = [ self.in_dir, 'sites' ]
    a.extend(site.split('.'))
    mod = a[-1]
    del a[-1]
    lib  = '/'.join(a)

    return [ lib, mod ]

  def _site_skip(self,site=None):
    if not site:
      site = self.page.site

    inc = self.list_sites_inc

    skip = 0 if site in inc else 1
    return skip

  def _skip(self,key=None):
    skip = self.page.get('skip',[])
    if key in skip:
      return 1
    return 0

  def _opt(self,key=None):
    opts = self.page.get('opts',[])
    if key in opts:
      return 1
    return 0

  def _act(self,key=None):
    acts = self.page.get('acts',[])
    if key in acts:
      return 1
    return 0

  def _cnf(self,key=None,default=None):
    if not key:
      return util.get(self,'cnf')

    val = util.get(self, f'cnf.{key}', default)
    return val

  def _url_saved_db(self,url=None):
    if not url:
      url = self.page.url
    rid = self._rid_url(url)
    return 0 if rid == None else 1

  def _url_saved_fs(self,url=None):
    if not url:
      url = self.page.url

    rid = self._rid_url(url)

    if rid == None:
      return 0

    self.ii_cache = self._file_rid({ 'rid' : rid })
    if os.path.isfile(self.ii_cache):
      return 1
    return 0

  def _page_from_rid(self,rid=None):
    q = '''SELECT * FROM pages WHERE rid = ?'''
    p = [rid]
    r = dbw.sql_fetchone(q,p,{ 'db_file' : self.dbfile.pages })

    row  = r.get('row',{})
    cols = r.get('cols',[])

    page = None
    if len(row):
      page = Page(row) 
      page.app = self

    return page

  def _rid_url(self,url=None):
    db_file = self.dbfile.pages
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    if not url:
      url = self.page.url

    q = '''SELECT rid FROM pages WHERE url = ?'''
    c.execute(q,[url])
    rw = c.fetchone()

    return ( rw[0] if rw else None )

  def _img_ext(self,imgobj=None):
    map = {
       'JPEG'  : 'jpg',
       'PNG'   : 'png',
       'GIF'   : 'gif',
    }
    ext = map.get(imgobj.format,'jpg')
    return ext
     
  def _ii_full(self):
    date = self.page.get('date')
    site = self.page.site

    ii_num = self._ii_num()
    self.page.set({ 'ii_num' : ii_num })

    a_f = self.page.get('author_id_first')
    a_fs = f'.{a_f}' if a_f else ''

    ii_full = f'{date}.site.{site}{a_fs}.{ii_num}.{self.page.ii}'

    return ii_full

  def _ii_num(self):

    ii_num = self.page.get('ii_num')
    if ii_num:
      return ii_num

    date = self.page.get('date')
    site = self.page.site

    a_f = self.page.get('author_id_first')
    a_fs = f'.{a_f}' if a_f else ''

    pattern = f'{date}.site.{site}{a_fs}.'

    db_file = self.dbfile.pages
    conn = sqlite3.connect(db_file)
    #conn.row_factory = sqlite3.Row
    c = conn.cursor()

    q = f'''SELECT 
                MAX(ii_num) 
            FROM pages 
                WHERE ( NOT url = ? ) AND ii_full LIKE "{pattern}%"
         '''
    c.execute(q,[ self.page.url ])    
    rw = c.fetchone()
    if rw[0] is not None:
      ii_num = rw[0] + 1
    else:
      ii_num = 1

    conn.commit()
    conn.close()

    return ii_num

  def _img_local_uri(self, url):
    if not ( self.dbfile.images and os.path.isfile(self.dbfile.images) ):
      pass
    else:
      conn = sqlite3.connect(self.dbfile.images)
      c = conn.cursor()

      c.execute('''SELECT img FROM imgs WHERE url = ?''',[ url ])
      rw = c.fetchone()

      conn.commit()
      conn.close()

      img = rw[0] if rw else None
      iuri = None
      if img:
        ipath = os.path.join(self.img_root,img)
        iuri = Path(ipath).as_uri()
      return iuri

  def cmt(self,cmt=''):
    pass
    return self

  def do_css(self):
    return self

  def page_save_sh(self,ref={}):
    file = self._file_rid({ 'tipe' : '_parse_cache', 'ext' : 'sh' })
    h = '''#!/bin/sh

bs.py -c html_parse -i cache.html $*

    '''
    with open(file, 'w') as f:
      f.write(h)

    st = os.stat(file)
    os.chmod(file,st.st_mode | stat.S_IEXEC)

    return self

###db_save
  def page_save_db_record(self,ref={}):
    file = self._file_rid({ 'tipe' : 'dbrid', 'ext' : 'html' })

    q = '''SELECT * FROM pages WHERE url = ? '''
    p = [ self.page.url ]
    dw = dbw.sql_fetchone(q,p,{ 'db_file' : self.dbfile.pages })
    if not dw:
      return self

    cols = dw.get('cols',[])
    row = dw.get('row',{})

    t = self.template_env.get_template("dbrid.t.html")
    h = t.render(row=row,cols=cols)

    with open(file, 'w') as f:
      f.write(h)

    return self

  def page_save_data(self,ref={}):
    ext  = ref.get('ext','txt')

    tipe  = ref.get('tipe',None)
    tipes = ref.get('tipes',[])

    tipes_a = tipes
    if type(tipes) is str:
      tipes_a = tipes.split(',')
    for tipe in tipes_a:
      self.page_save_data({ 'tipe' : tipe, 'ext' : ext })

    if not tipe:
      return self

    els = self.soup.select(tipe)
    txt = []
    data_file = self._file_rid({ 'tipe' : tipe, 'ext' : ext })
    for e in els:
      ms = str(e)
      txt.append(ms)
    with open(data_file, 'w') as f:
        f.write("\n".join(txt))

    return self

  def page_save_data_img(self,ref={}):
    tipe = ref.get('tipe','img')

    data_file_img = self._file_rid({ 
      'tipe' : tipe, 
      'ext'  : 'html' 
    })
    data = {}

    itms = []
    for el in self.soup.find_all("img"):
      itm = { 
        'uri'       : {},
        'uri_local' : {},
        'next' : None 
      }

      for k in [ 'data-src', 'src' ]:
        if el.has_attr(k):
           img_remote_rel = el[k] 
           img_remote = util.url_join(self.page.baseurl, img_remote_rel)
           img_local = self._img_local_uri(img_remote)
  
           itm['uri'][k] = img_remote_rel
           if img_local:
             itm['uri_local'][k] = img_local

      for k in [ 'alt' ]:
        if el.has_attr(k):
            itm[k] = el[k] 

      for ee in el.next_elements:
        s = ee.string
        if s:
          s = s.strip()
          if len(s):
            itm['next'] = s
            break

      s = str(el)
      se = jinja2.escape(s).rstrip()
      code = str(se)
      itm['code'] = code
      itms.append(itm)

    data.update({ 
      'itms'  : itms,
    })

    t = self.template_env.get_template("img.t.html")
    h = t.render(
      data=data,
      baseurl=self.page.baseurl
    )

    soup = BeautifulSoup(h,'html5lib')
    h = soup.prettify()

    with open(data_file_img, 'w') as f:
      f.write(h)
    return self

  def page_do_imgs(self):
    if self._act('no_img'):
     return self

    host    = self.page.host
    rid     = self.page.rid

    baseurl = self.page.baseurl
    site    = self.page.site

    img_dir = self._dir_ii_img()

    j = 0
    els_img = self.soup.select("img")
    #import pdb; pdb.set_trace()
    for el_img in els_img:
      j+=1
      caption = ''

      #if el_img.has_attr('alt'):
        #caption = el_img['alt']

      self.pic = pic = Pic({ 
        'app' : self,
        'el'  : el_img,
      })

      if not pic.url:
        continue

      self.log(f'[{rid}][page_do_imgs] Found image url: {pic.url}')

      get_img = 1

      if not self._act('get_img'):
        # image saved to fs && db
        if pic.img_saved:
          get_img = 0

###i
      if get_img:
        pic.grab()

      if not pic.img_saved:
        continue

      pic             \
        .el_replace() \
        .save2page()  \

    return self

  def render_page_list(self):

    t = self.template_env.get_template("list.t.html")
    h = t.render(pages=self.pages)

    h_file = self._dir('html list.html')

    with open(h_file, 'w') as f:
      f.write(h)

    h_uri = Path(h_file).as_uri()
    self.log(f'[BS] list: {h_uri}')

    return self

  def parse(self,urldata=[]):

    urldata = getattr(self,'urldata',urldata) 
    while len(urldata):
      d = urldata.pop(0)
      self.parse_url(d)
    
    return self

  def init(self):

    self                  \
      .init_dirs()        \
      .init_files()       \
      .init_npm()         \
      .init_db_pages()    \
      .init_db_images()   \
      .init_tmpl()        \
      .mk_dirs()          \
      .load_yaml()        \
      .load_zlan()        \

    return self

  def main(self):

    self                    \
      .get_opt()            \
      .do_cmd()             \

    return self


