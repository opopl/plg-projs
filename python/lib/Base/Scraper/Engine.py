
import requests
from bs4 import BeautifulSoup, Comment

import getopt,argparse
import sys,os,stat
import yaml
import re
import json

from tabulate import tabulate
from requests_html import HTMLSession

import logging
from http.client import HTTPConnection  # py3

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
from Base.Scraper.Page import Page

from Base.Mix.mixCmdRunner import mixCmdRunner
from Base.Mix.mixLogger import mixLogger
from Base.Mix.mixGetOpt import mixGetOpt
from Base.Mix.mixLoader import mixLoader
from Base.Mix.mixFileSys import mixFileSys

from Base.Scraper.Mixins.mxDB import mxDB

from http.server import BaseHTTPRequestHandler, HTTPServer
import time

class BS(CoreClass,
       mixLogger,
       mixCmdRunner,
       mixGetOpt,
       mixLoader,
       mixFileSys,

       mxDB,
  ):

  # class attributes {
  usage = '''
  PURPOSE
        This script will parse input URL
  EXAMPLES
        bs.py -y mix.yaml -p list_sites
        bs.py -c db_fill_tags
        bs.py -c db_fill_auth
  '''

  opts_argparse = [
    { 
       'arr' : '-y --f_yaml', 
       'kwd' : { 
           'help'    : 'input YAML file',
           'default' : '',
       } 
    },
    { 
       'arr' : '-z --f_zlan',
       'kwd' : { 
           'help'    : 'input ZLAN file',
           'default' : '',
       } 
    },
    { 
       'arr' : '-i --f_input_html', 
       'kwd' : { 
           'help'    : 'input HTML file',
           'default' : '',
       } 
    },
    { 
       'arr' : '-f --find', 
       'kwd' : { 
           'help'    : 'Find elements via XPATH/CSS',
           'default' : '',
       } 
    },
    { 
       'arr' : '-g --grep', 
       'kwd' : { 
           'help'    : 'Grep in input file(s)',
           'default' : '',
       } 
    },
    { 
       'arr' : '--gs', 
       'kwd' : { 
           'help'    : 'Grep scope',
           'default' : 10,
       } 
    },
    { 
       'arr' : '-p --print', 
       'kwd' : { 
           'help'    : 'Print field value and exit',
           'default' : '',
       } 
    },
    { 
       'arr' : '-c --cmd', 
       'kwd' : { 'help'    : 'Run command(s)' } 
    },
    { 
       'arr' : '-l --log', 
       'kwd' : { 'help' : 'Enable logging' } 
    },
  ]

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

  # code, e.g. html, tex
  code = {
    'tex' : None,
    'html' : None,
  }

  # lists
  lists = {}

  # output directory
  out_dir = None


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

  # list of url blocks to be fetched and parsed
  urldata = []

  # tables
  tb = {
      'create' : {
          'order' : [
              'pages',
              'data_meta',
              'page_pics',
              'page_tags',
              'page_authors',
              'authors',
              'tag_stats',
              'auth_stats',
              'log',
              'slova_citaty',
        ]
      }
    }

  # list of url blocks already processed
  parsed = []

  # order of keys for parsed
  keys_parsed = [ 
    'url'         ,
    'site'        ,
    'rid'         ,
    'title'       ,
    'title_h'     ,
    'date'        ,
    'tags'        ,
    'author_id'   ,
    'author_line' ,
    'author_urls' ,
    'cite'        ,
    'cite_h'      ,
    'piccount'    ,
  ]

  bin_subpaths = {
    'js'  : 'src',
    'mjs' : 'src',
  }

  # end: attributes }

###_i_engine
  def __init__(self,args={}):
    mxDB.init(self,args)

  def get_opt_apply(self):
    if not self.oa:
      return self

    for k in util.qw('f_yaml f_zlan f_input_html'):
      v  = util.get(self,[ 'oa', k ])
      m = re.match(r'^f_(\w+)$', k)
      if m:
        ftype = m.group(1)
        self.files.update({ ftype : v })

    return self

  def get_opt(self):
    if self.skip_get_opt:
      return self

    mixGetOpt.get_opt(self)

    self.get_opt_apply()

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
                height INTEGER, 
                img TEXT,
                inum INTEGER,
                name TEXT,
                proj TEXT,
                rootid TEXT,
                sec TEXT,
                tags TEXT,
                type TEXT, 
                url TEXT UNIQUE,
                url_parent TEXT, 
                width INTEGER,
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

    dir = self._dir('sql')
    ct_order = util.get(self,'tb.create.order',[])

    f_before = os.path.join(dir,f'before.sql')
    f_after  = os.path.join(dir,f'after.sql')

    sql_files = [ f_before ]

    for t in ct_order:
      f = os.path.join(dir,f'ct_{t}.sql')
      sql_files.append(f)

    sql_files.append(f_after)

    dbw.sql_do({ 
      'sql_files' : sql_files,
      'db_file'   : self.dbfile.pages
    })

    self.log('[init_db_pages] done')

    return self

  def init_logging(self):
    # log = logging.getLogger('requests.packages.urllib3')  # useless
    #log = logging.getLogger('urllib3')  # works
    
    #log.setLevel(logging.DEBUG)  # needed
    #fh = logging.FileHandler("requests.log")
    #log.addHandler(fh)
    
    #requests.get('http://httpbin.org/')

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



  def _yaml_data(self, f_yaml=None):
    if not f_yaml:
      f_yaml = self._file('yaml')

    if f_yaml and os.path.isfile(f_yaml):
      with open(f_yaml) as f:
        d = yaml.full_load(f)
        return d

    return 


  def load_lists(self):
    in_dir_lists = os.path.join(self.in_dir,'lists')
    if not os.path.isdir(in_dir_lists):
      return self

    for f in Path(in_dir_lists).glob('*.i.dat'):
      dat_file = f.as_posix()

      k = os.path.basename(f)
      m = re.match('^(.*)\.i\.dat$', k)
      if not m:
        continue

      lst_name = m.group(1)
      lst = util.readarr(dat_file)
      self.lists[lst_name] = lst

    return self

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
      #if self._site_skip():
        #need = False
        #break
  
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

  def _requests_get(self,ref={}):
    url     = util.get(ref,'url','')

    args_in = util.get(ref,'args',{})

    headers = {}
    headers = {
     'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.3'
    }

    args = { 
      'headers' : headers,
      'verify'  : True,
    }
    args_site = self._site_data('fetch.requests.args',{})

    args.update(args_site)
    args.update(args_in)

    r = requests.get(url,**args)

    return r

  def url_fetch(self,ref={}):
    url = ref.get('url',self.page.url)

    self.log(f'[url_fetch] fetching url: {url}')

    if self.page.get('fetched'):
      return self

    tries = util.qw('requests requests_html')
    tries = util.qw('requests')
    url_fetch_mode = ref.get('url_fetch_mode','requests')

    ok = 1
    r = None
    for tri in tries:
      if tri == 'requests':
        try:
          r = self._requests_get({ 'url' : url })
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
    '''
      call tree
        calls 
          url_load_content
            url_fetch
              _requests_get
    '''
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

    el_title = self.soup.select_one('head title')
    if el_title:
      t = el_title.get_text()
      t = util.strip(t)
      self.page.title = t

    h1 = self.soup.select_one('h1')
    title_h = ''
    if h1:
      s = h1.string
      if s:
        title_h =  util.strip(s)
        self.page.set({ 'title_h' : title_h })
        if not self.page.title:
          self.page.set({ 'title' : title_h })

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
      if type(css) in [ str ]:
        els = copy(self.soup.select(css))
      elif type(css) in [ list ]:
        s = css[0]
        index = css[1]
        css = s
        els = copy(self.soup.select(css))
        els = [ els[index] ]

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
    ext  = util.get(ref,'ext','html')

    css    = util.get(ref,'css','')
    xpath  = util.get(ref,'xpath','')

    act    = util.get(ref,'act','display')

    file_html = self._file_rid({ 
      'rid'  : rid, 
      'tipe' : tipe, 
      'ext'  : ext, 
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

    if not site:
      return self

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

    if not site:
      return self

    # site => news.eng.bbc
    #   lib => news/eng/bbc
    #   mod => bbc
    [ lib, mod ] = self._site_libdir(site)

    # create files + dirs, if not exist
    self.site_init_fs({ 
        'site' : site,
        'lib'  : lib,
        'mod'  : mod,
    })

    mod_py   = os.path.join(lib,mod + '.py')
    if not os.path.isfile(mod_py):
      return self

    libs     = [ lib ]

    # module name
    util.add_libs(libs)
    m = self.modules['sites'][site] = __import__(mod)

    if m:
      self.log(f'[in_load_site_module] loaded module for site: {site}' )
      p = self.page_parser = m.PageParser({ 
        'soup' : self.soup,
        'app'  : self,
      })
    else:
      self.page_parser = None

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
        self.log('WARN[page_load_ld_json] JSON decode errors')
        self.log(e.string)
        #raise
        #pass
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
    '''
        main => do_cmd => c_run => parse => parse_url => parse_url_run
    '''
    tipes_img = util.qw('img img_clean')

    acts = [
      [ 'in_load_site_module' ],
      [ 'in_load_site_yaml' ],
      [ 'load_soup' ],
      [ 'page_save_data_txt' ],
      [ 'db_save_meta' ],
      [ 'page_load_ld_json' ],
      [ 'update_ii' ],
      #[ 'in_load_site_yaml' ], - older call
      [ 'page_get_date' ],
      [ 'page_get_ii_full' ],
      #[ 'db_save_page' ],
      #save image data => img.html
      [ 'page_save_data_img' ],
      [ 'page_clean_core' ],
      [ 'page_rm_comments' ],
      [ 'page_save', [{ 'tipe' : 'core'}] ],
      [ 'page_clean' ],
      [ 'page_save', [{ 'tipe' : 'core_clean' }] ],
      [ 'page_only' ],
      #[ 'page_get_date' ],
      #[ 'page_get_ii_full' ],
      [ 'page_get_author' ],
      [ 'db_save_page' ],
      [ 'page_unwrap' ],
      [ 'page_rm_empty' ],
      [ 'page_header_insert_url' ],
      [ 'page_save' ],
      [ 'page_save_data_img', [{ 'tipe' : 'img_clean' }] ],
      [ 'page_do_imgs' ],
      [ 'page_replace_links', [{ 'act' : 'rel_to_remote' }] ],
      [ 'page_store_links' ],
      [ 'load_soup_file_rid', [{ 'tipes' : tipes_img }] ],
      [ 'ii_replace_links', [
          { 
            'tipes' : tipes_img, 
            'act' : 'remote_to_db' 
          }
      ] ],
      [ 'page_save' ],
      [ 'page_add' ],
      [ 'page_save_log' ],
      [ 'page2yaml' ],
      [ 'db_ok' ],
      [ 'page_save_db_record' ],
      [ 'page_save_sh' ],
      [ 'page_save2parsed' ],
    ]

    util.call(self,acts)

    return self

  def site_init_fs(self,ref={}):
    '''
    purpose
      create site *.py *.yaml files 
      create tree of site directories
    call tree
      called by
          in_load_site_module
    '''
    site = ref.get('site',self.page.site)

    mod  = ref.get('mod','')
    lib  = ref.get('lib','')


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
        'ok'  : 0,
        'app' : self,
    })

    # strings
    for k in util.qw('url date tags ii depth imgbase limit'):
      v = ref.get(k,'')
      if type(v) in [str]:
        v = v.strip()
      self.page.set({ k : v })

    d = util.url_parse(self.page.url)

    for k in util.qw('host baseurl'):
      v = d[k]
      v = v.strip()
      self.page.set({ k : v })

    self.page_set_lst(ref)

    if not self._need_process(ref):
      return self

    try:
      self.site_extract()
    except:
      if not self._opt('no_site'):
        return self

    if self._site_skip():
      return self

    self.log(f'[site_extract] site = {self.page.site}')

    self.log('=' * 100)
    self.log(f'[parse_url] start: {self.page.url}')

    self.parse_url_run()

    self.page_index = self.page_index + 1

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
    date = self.page.date 

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

    dy = yaml.dump(self.page.dict(), allow_unicode=True)
    yfile = self._file_rid({ 'tipe' : 'page', 'ext' : 'yaml' })
    util.mk_dirname(yfile)

    with open(yfile, 'w') as f:
      f.write(dy)

    return self

  def on_fail(self):

    self                            \
        .db_save_page({ 'ok' : 0 }) \
        .page_save_sh()             \
        .page_save_db_record()      \
        .page_save_log()            \
        .page2yaml()                \

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

    skips = self._site_data('unwrap.skip',[])

    do_cnt = 0
    while 1:
      div = self.soup.select_one('div')
      if not div:
        break

      div_attrs = util.get(div, 'attrs', {})
      div_attr_list = list(div_attrs.keys())
      #if 'dir' in div_attr_list:
        #import pdb; pdb.set_trace()

#      for sk in skips:
        #attr_eq = sk.get('attr_eq',{})
        #for a, v in attr_eq.items():
          #div_attr_val = util.get(div_attrs, a, '')
          #if div_attr_val == v:
            #do_break = 1

      #if do_cnt:
        #break

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

  def _db_get_taglist(self, ref={}):
    where = ref.get('where',{})

    db_file = self.dbfile.pages

    taglist = []

    lst = dbw.sql_fetchlist(
       '''SELECT tag FROM tag_stats ASC''',
       [],
       { 'db_file' : db_file,
         'where'   : where,
       })
    taglist = lst

#    for tg in lst:
      #if not tg:
        #continue
      #taglist.extend(tg.split(','))

    #taglist = util.uniq(taglist)
    #taglist.sort()

    return taglist

  def _db_get_authors(self, ref={}):
    where = ref.get('where',{})

    db_file = self.dbfile.pages

    wk = list(where.keys())
    flt = { 'auth_id' : [] }

    for k in wk:
      v = where.get(k,'')
      if k in util.qw('site date'):
        list_author_id = dbw.sql_fetchlist(
          '''SELECT DISTINCT author_id FROM pages''',
          [],
          { 'db_file' : db_file,
            'where'   : { k : v },
          })
        del where[k]

        for author_id in list_author_id:
          if not author_id:
            continue
          auth_ids = author_id.split(',')
          flt['auth_id'].extend(auth_ids)

    flt_len = {}
    for k in flt.keys():
      flt[k]     = util.uniq(flt[k])

      flt_len[k] = len(flt[k])

    r = dbw.sql_fetchall('''SELECT * FROM authors''',[],{
      'db_file' : db_file,
      'where'   : where,
    })

    authors = r.get('rows',[])
    cols    = r.get('cols',[])

    n = []
    for a in authors:
      auth_id = a.get('id','')
      if flt_len['auth_id'] and not auth_id in flt['auth_id']:
        continue
      n.append(a)

    authors = n

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

  def _db_author_urls(self, ref={}):
    author_id = ref.get('author_id','')
    auth_ids  = author_id.split(',')

    db_file = self.dbfile.pages

    q = 'SELECT url FROM page_authors'

    urls_a = None

    while auth_ids:
      auth_id = auth_ids.pop(0)

      urls_db = dbw.sql_fetchlist(q,[],{
        'db_file' : db_file,
        'where'   : { 
          'auth_id' : auth_id,
        }
      })

      urls_f = []
      for url in urls_db:
        ok = 1
        while 1:
          if urls_a == None:
            break

          if not (url in urls_a):
            ok = 0

          break
        
        if ok:
          urls_f.append(url)

      urls_a = urls_f

    return urls_a

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
        ok = 1
        while 1:
          if urls_a == None:
            break

          if not (url in urls_a):
            ok = 0

          break
        
        if ok:
          urls_f.append(url)

      urls_a = urls_f

    return urls_a

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

    if 'author_id' in where.keys():
      author_id = where.get('author_id','')
      urls = self._db_author_urls({ 'author_id' : author_id })

      del where['author_id']

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
    else:
      pages = rows
    
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

    q = '''SELECT id, name, url, plain FROM authors WHERE id = ?'''
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
  def c_db_fill_tags(self,ref={}):
    self.log(f'[c_db_fill_tags] processing tags...')

    db_file = self.dbfile.pages

    r = dbw.sql_fetchall(
        'SELECT rid,url,tags FROM pages',[],
        { 'db_file' : db_file }
    )
    rows = r.get('rows',[])

    for rh in rows:
      self.db_save_tags(rh)

    tag_list = dbw.sql_fetchlist(
      'SELECT DISTINCT tag FROM page_tags ORDER BY tag ASC',[],
      { 'db_file' : db_file }
    )

    for tag in tag_list:
      rids = dbw.sql_fetchlist(
        '''SELECT 
             DISTINCT CAST(rid AS TEXT) 
           FROM 
             page_tags 
           WHERE tag = ? ORDER BY rid ASC''',[ tag ],
        { 'db_file' : db_file }
      )
      rids_j = ','.join(rids)
      dbw.insert_dict({ 
        'db_file' : db_file,
        'table'   : 'tag_stats',
        'insert'  : { 
          'rids' : rids_j,
          'tag'  : tag,
          'rank' : len(rids),
        }
      })

    return self

  def c_db_fill_auth(self,ref={}):
    self.log(f'[c_db_fill_author] processing authors...')

    db_file = self.dbfile.pages

    r = dbw.sql_fetchall(
        'SELECT rid,url,author_id FROM pages',[],
        { 'db_file' : db_file }
    )
    rows = r.get('rows',[])

    for rh in rows:
      self.db_save_author(rh)

    auth_ids_all = dbw.sql_fetchlist(
      'SELECT DISTINCT auth_id FROM page_authors ORDER BY auth_id ASC',[],
      { 'db_file' : db_file }
    )

    for auth_id in auth_ids_all:
      rids = dbw.sql_fetchlist(
        '''SELECT 
             DISTINCT CAST(rid AS TEXT) 
           FROM 
             page_authors
           WHERE auth_id = ? ORDER BY rid ASC''',[ auth_id ],
        { 'db_file' : db_file }
      )
      rids_j = ','.join(rids)
      dbw.insert_dict({ 
        'db_file' : db_file,
        'table'   : 'auth_stats',
        'insert'  : { 
          'rids'    : rids_j,
          'auth_id' : auth_id,
          'rank'    : len(rids),
        }
      })

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

    acts = [
      [ 'init' ],
      [ 'fill_vars' ],
      [ 'print_field' ],
    ]

    util.call(self,acts)

    return self

  def c_init_bs(self):

    acts = [
      [ 'init' ],
      [ 'fill_vars' ],
    ]

    util.call(self,acts)

    return self

  def c_run(self,ref={}):
    urldata = util.get(ref,'urldata',[])
    if len(urldata):
      self.urldata = urldata

    acts = [
      [ 'c_init_bs' ],
      [ 'parse' ],
    ]

    util.call(self,acts)

    return self

  def c_zlan_save_fs(self,ref={}):

    acts = [
      [ 'c_init_bs' ],
      [ 'save_zlan_fs' ],
    ]

    util.call(self,acts)

    return self

  def save_zlan_fs(self,ref={}):

    self.log(f'[BS][save_zlan]')

    self.zlan.save2fs(ref)

    return self



  def db_ok(self):

    dbw.update_dict({
      'db_file'  : self.dbfile.pages,
      'table'    : 'pages',
      'where'    : { 'url' : self.page.url },
      'update'   : { 'ok' : 1 },
    })

    return self

  def db_save_author(self,ref = {}):

    author_id = ref.get('author_id',self.page.author_id)
    url  = ref.get('url',self.page.url)
    rid  = ref.get('rid',self.page.rid)

    if not author_id:
      return self

    auth_ids = author_id.split(',')
    if not auth_ids:
      return self

    self.log(f'[{rid}][db_save_author] saving authors: {author_id}')

    db_file = self.dbfile.pages

    auth_ids_db = dbw.sql_fetchlist(
       'SELECT auth_id FROM page_authors where url = ?',
       [url],
       { 'db_file' : db_file }
    )

    for auth_id in auth_ids:
      if auth_id in auth_ids_db:
        continue

      ins_auth = {
        'rid'     : rid,
        'url'     : url,
        'auth_id' : auth_id,
      }
      d = {
        'db_file' : db_file,
        'table'   : 'page_authors',
        'insert'  : ins_auth,
      }
      dbw.insert_dict(d)

    return self

  def db_save_tags(self,ref = {}):
    tags = ref.get('tags',self.page.tags)
    url  = ref.get('url',self.page.url)
    rid  = ref.get('rid',self.page.rid)

    self.log(f'[{rid}][db_save_tags] saving tags')

    db_file = self.dbfile.pages

    if not tags:
      return self

    tags_db = dbw.sql_fetchlist(
       'SELECT tag FROM page_tags where url = ?',
       [url],
       { 'db_file' : db_file }
    )

    tags_add = tags.split(',')

    for tag in tags_add:
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

      rids_db_s = dbw.sql_fetchval(
         'SELECT rids FROM tag_stats where tag = ?',
         [tag],
         { 'db_file' : db_file }
      )
      rids = []
      if rids_db_s:
        rids = rids_db_s.split(',')
        rids.append(rid)
        rids = util.uniq(rids)
      else:
        rids = [rid]

      rank = len(rids)

      rids_s = string.join(',', rids)
      d = {
        'db_file' : db_file,
        'table'   : 'tag_stats',
        'insert'  : {
          'tag'  : tag,
          'rids' : rids_s,
          'rank' : rank,
        },
      }
      dbw.insert_dict(d)

    return self

###db_save
# self.page => pages table 
# self.page.tags => page_tags table
#   see: db_save_tags()
  def db_save_page(self,ins = {}):

    db_file = self.dbfile.pages

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

    self                  \
        .db_save_tags()   \
        .db_save_author() \
    
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

    if not site:
      if self._opt('no_site'):
        return 0

    inc = self.list_sites_inc

    skip = 0 if site in inc else 1
    return skip

  def _skip(self,key=None):
    skip = self.page.get('skip',[])
    if key in skip:
      return 1
    return 0

  def _list(self,key=None,default=[]):
    lst = util.get(self,[ 'lists', key ],default)
    return lst

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

  def _pics_from_rid(self,rid=None):
    if rid == None:
      rid = self.page.rid

    r = dbw.sql_fetchall(
      'SELECT * FROM page_pics WHERE rid = ?',
      [rid],
      { 'db_file' : self.dbfile.pages }
    )
    rows = r.get('rows',[])
    for row in rows:
      pic_url = row.get('pic_url','')
      if not pic_url:
        continue

      r = dbw.sql_fetchone(
        'SELECT * FROM imgs WHERE url = ?',
        [ pic_url ],
        { 'db_file' : self.dbfile.images }
      )
      if not r:
        row_pic = {}
      else:
        row_pic = r.get('row',{})

      for k in util.qw('caption width height inum ext img'):
        v = row_pic.get(k,'')
        row.update({ k : v})

    return rows

  def _page_from_rid(self, rid_s=None ):
    m = re.match(r'^(\d+)$',rid_s)

    rid = None
    if not m:
      if rid == 'last':
        rid = self._rid_last()
    else:
      rid = rid_s

    if rid == None:
      return None

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

  def page_save2parsed(self):
    '''
      see also:
        parsed_report
    '''
    rid = self.page.rid

    p = {}
    defaults = {}
    ref = {
        'dest'     : p,
        'source'   : self.page,
        'keys'     : self.keys_parsed,
        'defaults' : defaults,
        'default'  : ''
    }
    util.obj_update(**ref)

    # e.g. Іван Сідоров; Коля Петренко - semicolon separated list of
    #   'plain' author strings
    author_line = ''
    author_urls = ''

    author_id = self.page.author_id
    if author_id:
      ids = author_id.split(',')

      author_line_a = []
      author_urls_a = []

      for id in ids:
        auth  = self._db_get_auth({ 'auth_id' : id })

        plain = util.get(auth,'plain','')
        url   = util.get(auth,'url','')

        if plain:
          author_line_a.append(plain)

        if url:
          author_urls_a.append(url)
  
      author_line = '; '.join(author_line_a)
      author_urls = '\n'.join(author_urls_a)

    date = self.page.date
    date_dot = ''
    if date:
      dt = datetime.datetime.strptime(date,'%d_%m_%Y')
      date_dot  = dt.strftime('%d.%m.%Y')
      #date_lang  = dt.strftime('%d.%m.%Y')

      date_all = f'{date}; {date_dot}'
    else:
      date_all = ''

    media = self.page.host
    cite_keys = [ 'cite', 'cite_h' ]


    cite = ''
    if self.page.title:
      cite = f'\citTitle{ {self.page.title} }, {author_line}, {media}, {date_dot}'
      cite = re.sub(r"\\citTitle{'(.*)'}(.*)", r'\\citTitle{\1}\2', cite)

    cite_h = ''
    if self.page.title_h:
      cite_h = f'\citTitle{ {self.page.title_h} }, {author_line}, {media}, {date_dot}'
      cite_h = re.sub(r"\\citTitle{'(.*)'}(.*)", r'\\citTitle{\1}\2', cite_h)

    pics = self._pics_from_rid(rid)
    piccount = len(pics)
    p.update({ 
      'piccount'    : len(pics),
      'author_line' : author_line,
      'author_urls' : author_urls,
      'date'        : date_all,
      'cite'        : cite,
      'cite_h'      : cite_h,
    })
    self.parsed.append(p)

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

  def parsed_report(self,urldata=[]):
    '''
        see also:
          page_save2parsed
          keys_parsed
    '''
    if not len(self.parsed):
      return self
    
    page_count = len(self.parsed)
    rids = list(map(lambda x: str(x['rid']), self.parsed))
    rids_s = ','.join(rids)

    self.log('Parse Report')
    i = 0
    while len(self.parsed):
      i+=1
      p = self.parsed.pop(0)
      self.log(f'page {i}')
      for k in self.keys_parsed:
        v = util.get(p,k)
        s = '  %-15s%-12s' % (k, v)
        self.log(s)

    self.log(f'Parsed {page_count} pages')
    self.log(f'  rids: {rids_s}')

    return self

  def parse(self,urldata=[]):
    '''
      Usage
        self.parse()
        self.parse(urldata)

      Call tree
        calls
          parse_url
            Page()          - initialize Page object instance
            site_extract    - extract site

            parse_url_run
              in_load_site_module
              in_load_site_yaml

              load_soup
                url_load_content
                  url_fetch
                    _requests_get
              ...

          parsed_report
    '''
    if not len(urldata):
      urldata = getattr(self,'urldata',[]) 

    self.page_index = 0
    while len(urldata):
      d = urldata.pop(0)
      self.parse_url(d)

      if self.page.limit:
        if self.page_index == self.page.limit:
           break

    self.parsed_report()

    return self

  def init(self):

    acts = [
      [ 'init_dirs' ],
      [ 'init_files' ],
      [ 'init_npm' ],
      [ 'init_db_pages' ],
      [ 'init_db_images' ],
      [ 'init_logging' ],
      [ 'init_tmpl' ],
      [ 'mk_dirs' ],
      [ 'load_yaml' ],
      [ 'load_lists' ],
      [ 'load_zlan' ],
    ]

    util.call(self,acts)

    return self

  def main(self):

    acts = [
      [ 'get_opt' ],
      [ 'do_cmd' ],
    ]

    util.call(self,acts)

    return self
