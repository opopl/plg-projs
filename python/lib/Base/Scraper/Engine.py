
import requests
from bs4 import BeautifulSoup, Comment

import getopt,argparse
import sys,os
import yaml
import re

import sqlite3
import sqlparse
import cairosvg

import html.parser

from pathlib import Path
from urllib.parse import urlparse
from urllib.parse import urljoin

from url_normalize import url_normalize
from copy import copy

from PIL import Image
from PIL import UnidentifiedImageError

from io import StringIO

from npm.bindings import npm_run

#from jinja2 import Template

import jinja2
import shutil

import cyrtranslit

import os,sys

import Base.DBW as dbw
import Base.Util as util
import Base.Const as const

from Base.Zlan import Zlan

from Base.Core import CoreClass

class dbFile(CoreClass):
  images = None
  pages = None

class mixLogger:

  def die(self,msg=''):
    self.log_db(msg)
    raise Exception(msg)    

    return self

  def log(self,msg=[]):
    if type(msg) is list:
      for m in msg:
        self.log(m)
      return self
  
    if not type(msg) is str:
      return self
      
    print(msg)
    self.log_db(msg)
    
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
  baseurl = None
  host    = None
  rid     = None
  site    = None
  url     = None
  pass

class Pic(CoreClass):
  url = None

  def grab(pic):
    app = pic.app

    app.log(f"[page_do_imgs] Getting image: \n\t{pic.url}")

    i = None
    resp = requests.get(pic.url, stream = True)
    resp.raw.decoded_content = True

    i_tmp = { 
       'bare' : app._dir('tmp_img bs_img'),
       'png'  : app._dir('tmp_img bs_img.png'),
    }
    with open(i_tmp['bare'], 'wb') as lf:
      shutil.copyfileobj(resp.raw, lf)

    ct = resp.headers['content-type']

    #resp.raw type is urllib3.response.HTTPResponse

    # Image class instance
    i = None
    try:
      i = Image.open(i_tmp['bare'])
      #i = Image.open(resp.raw)
    except UnidentifiedImageError:

      if ct in [ 'image/svg+xml' ]:
        cairosvg.svg2png( 
          file_obj=open(i_tmp['bare'], "rb"),
          write_to=i_tmp['png']
        )
        i = Image.open(i_tmp['png'])
      
    if not i:
      app.log(f'FAIL[page_do_imgs] no Image.open instance: {pic.url}')
      return pic
      
    app.log(f'[page_do_imgs] Image format: {i.format}')
    pic.ext = app._img_ext(i)

    dd = { 
      'url'  : pic.url,
      'ext'  : pic.ext,
    }
    if not pic.img_saved:
      dd.update({ 'opts' : 'new' })

    pic.idata = app._img_data(dd)

    pic.img   = pic.idata.get("img","")
    pic.inum  = pic.idata.get('inum','')
    pic.ipath = pic.idata.get('path','')

    app.log(f'[page_do_imgs] Local path: {pic.idata.get("path","")}')
    if os.path.isfile(pic.ipath):
      app.log(f'WARN[page_do_imgs] image file already exists: {pic.img}')

    a = {}
    if pic.ext == 'gif':
      a['save_all'] = True

    i.save(pic.ipath,**a)
    i.close()

    app.log(f'[page_do_imgs] Saved image: {pic.img}')

    insert =  {
        'url_parent' : app.url,
    }
    for k in util.qw('url img inum ext caption'):
      insert[k] = getattr(pic,k,None)

    for k in util.qw('proj rootid'):
      insert[k] = getattr(app,k,None)

    d = {
      'db_file' : app.dbfile.images,
      'table'   : 'imgs',
      'insert'  : insert
    }
    dbw.insert_dict(d)
    
    return pic

class BS(CoreClass,mixLogger):
  # class attributes {
  usage='''
This script will parse input URL
'''

  html_parser = html.parser.HTMLParser()

  # data
  data = {}

  # global variables
  globals = {}

  # loaded python modules
  modules = { 
    'sites' : {}
  }

  # current page's base URL
  base_url = None

  # current HTML content
  content = None

  # directories
  dirs = {}

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

  # list of databases
  dbfile = dbFile()

  # list of urls to be fetched and parsed
  urls = []

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


  def get_opt(self):
    self.parser = argparse.ArgumentParser(usage=self.usage)
    
    self.parser.add_argument("-u", "--url", help="input URL",default="")
    self.parser.add_argument("-y", "--f_yaml", help="input YAML file",default="")
    self.parser.add_argument("-z", "--f_zlan", help="input ZLAN file",default="")
    
    self.oa = self.parser.parse_args()

    if len(sys.argv) == 1:
      self.parser.print_help()
      sys.exit()

    for k in util.qw('f_yaml f_zlan'):
      v  = util.get(self,[ 'oa', k ])
      m = re.match(r'^f_(\w+)$', k)
      if m:
        ftype = m.group(1)
        self.files.update({ ftype : v })

    return self

  def init_tmpl(self):
    self.template_loader = jinja2.FileSystemLoader(searchpath=self._dir('tmpl'))
    env  = jinja2.Environment(loader=self.template_loader)
    env.globals['url_join'] = util.url_join

    self.template_env = env

    return self

###db
  def init_db_urls(self):
    self.log('[init_db_urls]')
  
    sql = '''
            -- ALTER TABLE urls ADD COLUMN baseurl TEXT;
            -- ALTER TABLE urls ADD COLUMN host TEXT;

            DROP TABLE IF EXISTS log;

            CREATE TABLE IF NOT EXISTS urls (
                baseurl TEXT,
                host TEXT,
                rid INTEGER UNIQUE,
                remote TEXT UNIQUE NOT NULL,
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
                encoding TEXT
            );

            CREATE TABLE IF NOT EXISTS authors (
                id TEXT NOT NULL UNIQUE,
                url TEXT,
                name TEXT
            );

            CREATE TABLE IF NOT EXISTS tags (
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
    f = self._file('package_json')
    if not os.path.isfile(f):
      os.chdir(self._dir('html'))
      pass

    return self

  def init_files(self):
    self.files.update({ 
        'package_json' : self._dir('html','package.json')
    })

    return self

  def init_dirs(self):
    if not self._file('script'):
      self.files.update({
          'script' : os.path.realpath(__file__),
      })
    self.log(f'[BS] Script location: {self._file("script")}')

    if not self._dir('bin'):
      self.dirs.update({
          'bin' : str(Path(self.files['script']).parent),
      })
    
    if not util.get(self,'dirs.tmpl'):
      self.dirs['tmpl'] = os.path.join(self._dir('bin'),'tmpl')
    self.log(f'[BS] Template directory: {self._dir("tmpl")}')

    f_yaml = self._file('yaml')

    if f_yaml:
      pp = Path(f_yaml).resolve()
      dir = str(pp.parent)
      stem = pp.stem

      self.dirs.update({
          'out'      : os.path.join(dir,'out',stem),
          'in'       : os.path.join(dir,'in'),
          'in_sites' : os.path.join(dir,'in','sites'),
      })
    
    self.dirs.update({ 
      'html'       : self._dir('out' , 'html'),
      'tex_out'    : self._dir('out' , 'tex'),
      'tmp_img'    : self._dir('img_root', 'tmp' ),
    })

    return self

  def mk_dirs(self):
    for k,v in self.dirs.items():
      #os.makedirs(v,exist_ok=True)
      Path(v).mkdir(exist_ok=True)

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

    z = Zlan({})

    z.get_data({ 'file' : f_zlan })

    zdata = z.data
    zorder = z.order

    if not self.urls:
      self.urls = []

    for k in zdata.keys():
      if k in util.qw('order lines_main lines_eof'):
        continue
        
      url = k
      d = zdata.get(url)
      if not d.get('off'):
        self.urls.append(d)

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

    dir = os.path.join(self.html_root,'bs',str(rid))

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

  def _need_skip(self,ref={}):

    ok = 1 if not ref.get('redo',0) \
      and ( self._site_skip() or self._url_saved_fs() )  \
      else 0

    return ok

  def _need_load_cache(self):
    ok = 1 if not self._act('fetch')  \
      and self.page.mode == 'saved' \
      and os.path.isfile(self.ii_cache) else 0

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
    r = requests.get(url,headers=headers)

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

    self.log(f'[load_soup_file_rid] tipe: {tipe}')

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

  def page_add(self):
    uri_dict = {
        'base'   : self.page.baseurl,
        'remote' : self.page.url,
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
      'rid'   : self.page.rid,
      'uri'   : uri_dict
    })

    if self.page.len():
      self.pages.append(self.page)

    return self

  def fill_vars(self):
    self.fill_list_hosts()
    return self

  def fill_list_hosts(self):

    hosts = util.get(self,'hosts',[])
    l = [ hosts.get(x).get('site','') for x in hosts.keys() ]
    l = list(set(l))
    l = list(filter(lambda x: len(x) > 0,l))
    self.list_hosts = l

    inc = util.get(self,'include.sites',[])
    exc = util.get(self,'exclude.sites',[])

    if len(exc) == 0:
      inc = self.list_hosts

    for lst in [ inc, exc ]:
      for i in lst:
        if i == '_all_':
          lst.extend(self.list_hosts)
          lst.remove('_all_')

    self.list_hosts_inc = inc
    self.list_hosts_exc = exc


    return self

  def _site_data(self,path=None):
    d = None

    site = self.page.site

    if not path:
      return util.get(self,'sites.{site}')

    if type(path) is str:
      d = util.get(self,'sites.{site}.{path}')

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

    libs = [ lib ]
    mod_py = os.path.join(lib,mod + '.py')
    mod_yaml = os.path.join(lib,mod + '.yaml')

    if not os.path.isdir(lib):
      Path(lib).mkdir(exist_ok=True)

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

    in_dir = self._dir('in_sites')
    pieces = site.split('.')
    pieces.pop()
    for piece in pieces:
      init_py = os.path.join(in_dir,'__init__.py')
      if not os.path.isfile(init_py):
         Path(init_py).touch()

      in_dir = os.path.join(in_dir,piece)

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
    tipes = 'meta,script,img,link,head'

    self.page_save_data({ \
      'tipes' :  tipes    \
    })                    \

    return self

###pu
  def parse_url_run(self,ref={}):
    tipes = util.qw('img img_clean')

    self                                                \
        .load_soup()                                    \
        .page_save_data_txt()                           \
        .in_load_site_module()                          \
        .update_ii()                                    \
        .in_load_site_yaml()                            \
        .page_get_date()                                \
        .page_get_author()                              \
        .page_get_ii_full()                             \
        .db_save_url()                                  \
        .cmt(''' save image data => img.html''')        \
        .page_save_data_img()                           \
        .page_clean_core()                              \
        .page_rm_comments()                             \
        .page_save({ 'tipe' : 'core' })                 \
        .page_clean()                                   \
        .page_unwrap()                                  \
        .page_rm_empty()                                \
        .page_header_insert_url()                       \
        .page_save()                                    \
        .page_save_data_img({ 'tipe' : 'img_clean' })   \
        .page_do_imgs()                                 \
        .page_replace_links({ 'act' : 'rel_to_remote'}) \
        .load_soup_file_rid({                           \
            'tipes' : tipes                             \
        })                                              \
        .ii_replace_links({                             \
            'tipes' : tipes,                            \
            'act'  : 'remote_to_db',                    \
        })                                              \
        .page_save()                                    \
        .page_save_db_record()                          \
        .ii_insert_js_css({                             \
            'tipes' : util.qw('core clean'),            \
        })                                              \
        .page_add()                                     \
        .page_save_log()                                \

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
      self.die(f'[WARN] no site for url: {self.page.url}')
  
    return self

  def page_set_acts(self,ref={}):

    acts = ref.get('acts')
    if acts:
      acts_a = []
      if type(acts) is list:
        acts_a = acts
      elif type(acts) is str:
        acts_a = acts.split(',')

      if acts_a:
        self.page.set({ 'acts' :  acts_a })

    self.page.set({ 'tags' : ref.get('tags') })

    return self
  
  def parse_url(self,ref={}):
    url = ref.get('url','')

    if not url or url == const.plh:
      return self

    ii  = ref.get('ii','')
    self.page = Page({ 'url' : url, 'ii' : ii })

    d = util.url_parse(self.page.url)

    for k in util.qw('host baseurl'):
      v = d[k]
      self.page.set({ k : v })

    try:
      self.site_extract()
    except:
      return self

    self.page_set_acts(ref)

    if self._need_skip(ref):
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
      self.die(f'[page_get_author] no author!')

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
    if not util.get(self,'page.date'):
      self.die(f'[page_get_date] no date!')

    self.log(f'[page_get_date] got date: {self.page.date}')

    return self

  def page_rm_empty(self):
    all = self.soup.find_all(True)
    while 1:
      if not len(all):
        break

      el = all.pop(0)
      if el.name == 'img':
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
          self.ii_insert_js_css(r)
        return self

    self.log(f'[ii_insert_js_css] {tipe}')

    svf = self._file_rid({ 'tipe' : tipe, 'ext' : ext })
    self.load_soup_file_rid({                           \
        'tipe' : tipe,
        'ext'  : ext,
    })
    ii_soup = self.soups[svf]
    body = ii_soup.body
    script = ii_soup.new_tag('script')
    script['src'] = Path(self._dir('bin'),'ii.js').as_uri()
    body.append(script)

    style = ii_soup.new_tag('style')
    style.string = '''
        body {
          width: 700px;
        }
    '''
    ii_soup.head.append(style)

    with open(svf, 'w') as f:
      f.write(ii_soup.prettify())

    return self

  def ii_replace_links(self,ref={}):
    tipe = ref.get('tipe','cache')
    ext  = ref.get('ext','html')
    act  = ref.get('act','rel_to_remote')

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

    self.log(f'[ii_replace_links] {tipe}')

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
            u = urlparse(href)
            if not u.netloc:
              href = util.url_join(self.page.baseurl,href)
              next['href'] = href
            next['target'] = '_blank'
          elif act == 'remote_to_db':
            idata = self._img_data({ 'url' : href })
            if idata:
              uri_local = idata.get('uri')
              if uri_local:
                next['href'] = uri_local
                next['class'] = 'link uri_local'

    return self

  def page_unwrap(self):
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

    q = '''SELECT MAX(rid) FROM urls'''
    c.execute(q)
    rw = c.fetchone()
    rid = rw[0]
    if rid == None:
      rid = 0

    rid += 1

    conn.commit()
    conn.close()

    return rid

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

  # called by
  #   load_soup
  def db_save_url(self):

    db_file = self.dbfile.pages
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    self.page.rid = self._rid_new()
    if self._url_saved_db():
      self.page.rid = self._rid_url()
      if not self._act('db_update'):
        return self

    insert = {
      'remote' : self.page.url,
    }

    kk = '''date title_h tags encoding author_id author_id_first ii_num ii_full'''
    kk = kk + ''' rid ii site title'''
    for k in kk.split(' '):
      insert.update({ k : self.page.get(k) })

    d = {
      'db_file' : self.dbfile.pages,
      'table'   : 'urls',
      'insert'  : insert,
    }
    dbw.insert_dict(d)

    self.log(f'[db_save_url] url saved with rid {self.page.rid}')

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

    inc = self.list_hosts_inc

    skip = 0 if site in inc else 1
    return skip

  def _skip(self,key=None):
    skip = self.page.get('skip',[])
    if key in skip:
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

  def _rid_url(self,url=None):
    db_file = self.dbfile.pages
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    if not url:
      url = self.page.url

    q = '''SELECT rid FROM urls WHERE remote = ?'''
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
            FROM urls 
                WHERE ( NOT remote = ? ) AND ii_full LIKE "{pattern}%"
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

      img = rw[0] if rw else None
      iuri = None
      if img:
        ipath = os.path.join(self.img_root,img)
        iuri = Path(ipath).as_uri()
      return iuri

  def _img_data(self, ref={}):
    url    = ref.get('url','')
    ext    = ref.get('ext','jpg')

    opts_s = ref.get('opts','')
    opts   = opts_s.split(',')

    if not ( self.dbfile.images and os.path.isfile(self.dbfile.images) ):
      return 

    d = None

    conn = sqlite3.connect(self.dbfile.images)
    c = conn.cursor()

    img = None
    while 1:
      if 'new' in opts:
        c.execute('''SELECT MAX(inum) FROM imgs''')
        rw = c.fetchone()
        inum = rw[0]
        inum += 1
        img = f'{inum}.{ext}'
        break
      else:
        c.execute('''SELECT img, inum FROM imgs WHERE url = ?''',[ url ])
        rw = c.fetchone()
  
        if rw:
          img = rw[0]
          inum = rw[1]
      break

    if img:
      ipath = os.path.join(self.img_root, img)
  
      d = { 
        'inum'   : inum,
        'img'    : img,
        'remote' : url,
        'path'   : ipath,
        'uri'    : Path(ipath).as_uri()
      }

    return d

  def _img_saved(self,url):
    ok = 0
    if not ( self.dbfile.images and os.path.isfile(self.dbfile.images) ):
      pass
    else:
      conn = sqlite3.connect(self.dbfile.images)
      c = conn.cursor()

      c.execute('''SELECT img FROM imgs WHERE url = ?''',[ url ])
      rw = c.fetchone()
      if rw:
        img = rw[0]
        ipath = os.path.join(self.img_root, img)
        if os.path.isfile(ipath):
          ok = 1

      conn.commit()
      conn.close()

    return ok

  def cmt(self,cmt=''):
    pass
    return self

  def do_css(self):
    return self

###db_save
  def page_save_db_record(self,ref={}):
    file = self._file_rid({ 'tipe' : 'dbrid', 'ext' : 'html' })

    q = '''SELECT * FROM urls WHERE remote = ? '''
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

    baseurl = self.page.baseurl
    site    = self.page.site

    img_dir = self._dir_ii_img()

    j = 0
    els_img = self.soup.find_all("img")
    for el_img in els_img:
      j+=1
      caption = ''

      self.pic = pic = Pic({ 'app' : self })
      #if el_img.has_attr('alt'):
        #caption = el_img['alt']

      if el_img.has_attr('src'):
        src = el_img['src'].strip()

        if src == '#':
          continue

        rel_src = None
        u = util.url_parse(src)

        if not u['netloc']:
          url = util.url_join(baseurl,src)
          rel_src = src
        else:
          url = u['url']

        pic.url = url
        self.log(f'Found image url: {url}')

        get_img = 1

        pic.img_saved = self._img_saved(url)

        if not self._act('get_img'):
          # image saved to fs && db
          if pic.img_saved:
            pic.idata = self._img_data({ 'url' : url })
            pic.ipath = pic.idata.get('path','')
            get_img = 0

###i
        if get_img:
          pic.grab()

        ipath_uri = Path(pic.ipath).as_uri()
        el_img['src'] = ipath_uri
        
        n = self.soup.new_tag('img')
        n['src'] = ipath_uri
        n['rel-src'] = rel_src
        n['width'] = 500
        el_img.wrap(self.soup.new_tag('p'))
        el_img.replace_with(n)

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

  def parse(self):

    urls = getattr(self,'urls',[]) 
    for d in urls:
      self.parse_url(d)
    
    return self

  def init(self):

    self                  \
      .init_dirs()        \
      .init_files()       \
      .init_npm()         \
      .init_db_urls()     \
      .init_tmpl()        \
      .mk_dirs()          \
      .load_yaml()        \
      .load_zlan()        \

    return self

  def main(self):

    self                  \
      .get_opt()          \
      .init()             \
      .fill_vars()        \
      .parse()            \
      .render_page_list() \


