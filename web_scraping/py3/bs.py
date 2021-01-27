#!/usr/bin/env python3

import requests
from bs4 import BeautifulSoup

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

#from jinja2 import Template

import jinja2
import shutil

import cyrtranslit

import os,sys

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)

plg = os.environ.get('PLG')
add_libs([ os.path.join(plg,'projs','python','lib') ])
import Base.DBW as dbw
import Base.Util as util
import Base.Const as const

class BS:
  # class attributes {
  usage='''
This script will parse input URL
'''

  html_parser = html.parser.HTMLParser()

  # data
  data = {}

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

  # code, e.g. html, tex
  code = {
    'tex' : None,
    'html' : None,
  }

  # input directory
  in_dir = os.path.join(os.getcwd(),'in')

  # input YAML file
  f_yaml = None

  # input URL
  url = None

  # output directory
  out_dir = None

  #command-line options
  oa = None

  # pages - stored info about processed urls
  pages = []

  # current page data
  page = {}

  # beautiful soup instance for the current page
  soup = None

  # soups
  soups = {}

  # current site
  site = None

  # site-specific data
  sites = {}

  # Page class instance from loaded site module
  page_obj_site = None

  # tex lines
  tex_lines = []

  # image database
  img_db = None
  img_conn = None

  # rid
  rid = 0

  # url database
  url_db = None
  url_conn = None

  # end: attributes }

  def __init__(self,args={}):
    self.img_root = os.environ.get('IMG_ROOT')
    self.html_root = os.environ.get('HTML_ROOT')

    for k, v in args.items():
      setattr(self, k, v)

    for k in util.qw('img_root html_root'):
      self.dirs[k] = util.get(self,k) 

    if (not self.img_db) and self.img_root:
      self.img_db = os.path.join(self.img_root,'img.db')

    if (not self.url_db) and self.html_root:
      self.url_db = os.path.join(self.html_root,'h.db')


  def get_opt(self):
    self.parser = argparse.ArgumentParser(usage=self.usage)
    
    self.parser.add_argument("-u", "--url", help="input URL",default="")
    self.parser.add_argument("-y", "--f_yaml", help="input YAML file",default="")
    
    self.oa = self.parser.parse_args()

    if len(sys.argv) == 1:
      self.parser.print_help()
      sys.exit()

    self.url    = self.oa.url
    self.f_yaml = self.oa.f_yaml

    return self

  def init_tmpl(self):
    self.template_loader = jinja2.FileSystemLoader(searchpath=self._dir('tmpl'))
    env  = jinja2.Environment(loader=self.template_loader)
    env.globals['url_join'] = util.url_join

    self.template_env = env

    return self

  def init_db_urls(self):
    self.log('[init_db_urls]')
  
    sql = '''
            CREATE TABLE IF NOT EXISTS urls (
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

            DROP TABLE IF EXISTS log;

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
      'db_file' : self.url_db
    })

    return self

  def init_dirs(self):
    self.Script = os.path.realpath(__file__)
    self.Bin = str(Path(self.Script).parent)
    
    self.dirs['tmpl'] = os.path.join(self.Bin,'tmpl')
    self.log(f'[BS] Script location: {self.Script}')
    self.log(f'[BS] Template directory: {self.dirs["tmpl"]}')

    if self.f_yaml:
      pp = Path(self.f_yaml).resolve()
      dir = str(pp.parent)
      stem = pp.stem
      self.dirs['out'] = os.path.join(dir,'out',stem)
    
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
      f_yaml = self.f_yaml

    if f_yaml and os.path.isfile(f_yaml):
      with open(f_yaml) as f:
        d = yaml.full_load(f)
        return d

    return 

  def load_yaml(self, f_yaml=None):
    if not f_yaml:
      f_yaml = self.f_yaml

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
    rid = ref.get('rid',self.rid)

    dir = os.path.join(self.html_root,'bs',str(rid))

    return dir

  def _dir_ii_img(self):
    img_dir = os.path.join(self._dir_ii(),'img')
    if not os.path.isdir(img_dir):
      os.makedirs(img_dir,exist_ok=True)
    return img_dir

  def _file_ii_uri(self,ref={}):
    ii_file = self._file_ii(ref)
    uri = Path(ii_file).as_uri()
    return uri

  def _file_ii(self,ref={}):
    tipe = ref.get('tipe','cache')
    ext  = ref.get('ext','html')
    rid  = ref.get('rid',self.rid)

    ii_file = os.path.join(self._dir_ii({ 'rid' : rid }),f'{tipe}.{ext}')
    return ii_file

  def url_load_content(self,ref={}):
    if not self._act('fetch'):
      if os.path.isfile(self.ii_cache):
        with open(self.ii_cache,'r') as f:
          self.content = f.read()
          return self

      self.url_fetch()
      return self

    self.url_fetch()

    return self

  def url_fetch(self,ref={}):
    url = ref.get('url',self.url)

    self.log(f'[url_fetch] fetching url: {url}')

    if self.page.get('fetched'):
      return self

    headers = {
     'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.3'
    }
    r = requests.get(url,headers=headers)

    encoding = 'utf-8'
    if 'charset' in r.headers.get('content-type', '').lower():
      encoding = r.encoding
    self.page['encoding'] = encoding

    self.content = r.content
    bs = BeautifulSoup(self.content,'html5lib')
    self.content = bs.prettify()

    self.page_save_cache()

    self.page['fetched'] = 1

    return self

  def page_save_cache(self):

    util.mk_parent_dir(self.ii_cache)

    with open(self.ii_cache, 'w') as f:
      f.write(self.content)

    return self

  def load_soup_file_ii(self,ref={}):
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
          self.load_soup_file_ii(r)
        return self

    self.log(f'[load_soup_file_ii] tipe: {tipe}')

    file = self._file_ii({ 'tipe' : tipe, 'ext' : ext })

    if os.path.isfile(file):
      with open(file,'r') as f:
        html = f.read()
        self.soups[file] = BeautifulSoup(html,'html5lib')

    return self

  def log(self,msg=[]):
    if type(msg) is list:
      for m in msg:
        self.log(m)
      return self
  
    if not type(msg) is str:
      return self
      
    print(msg)
  
    db_file = self.url_db
    conn = sqlite3.connect(db_file)
    c = conn.cursor()
  
    insert = {
        'msg'   : msg,
        'rid'   : self.rid,
        'url'   : self.url,
        'site'  : self.site,
        'time'  : util.now()
    }
  
    d = {
       'db_file' : self.url_db,
       'table'   : 'log',
       'insert'  : insert,
    }
    dbw.insert_dict(d)
    
    return self

  def load_soup(self,ref={}):
    url = ref.get('url',self.url)
    ii  = ref.get('ii',self.ii)

    self.rid = self._rid_url(url)
    if not self.rid:
      self.rid = self._rid_free()

    self.ii_cache = self._file_ii()
    self.url_load_content()

    self.soup = BeautifulSoup(self.content,'html5lib',from_encoding=self.page.get('encoding'))

    self.title = self.soup.select_one('head > title').string.strip("\'\"\n\t ")

    h1 = self.soup.select_one('h1')
    title_h = ''
    if h1:
      s = h1.string
      if s:
        title_h = self.page['title_h'] = s.strip("\'\"\n")

    self.log(f'[load_soup] rid: {self.rid}, title: {self.title}')
    self.log(f'[load_soup] rid: {self.rid}, title_h: {title_h}')
    
    return self

  def _clean_base(self):
    clean = []
    clean.extend( util.get(self,'cnf.sel.clean',[]) )

    return clean
     
  def _clean(self, site=None):
    if not site:
      site = self.site

    clean = []
    clean.extend( self._clean_base() )
    clean.extend( util.get(self,[ 'sites', site, 'sel', 'clean' ],[]) )
    
    return clean

  def page_clean(self):
    site = util.get(self,'site','')

    clean = self._clean(site)
    for c in clean:
      els_clean = self.soup.select(c)
      for el in els_clean:
        el.decompose()

    return self

  def page_header_insert_url(self):
    h = self.soup.select_one('h1,h2,h3,h4,h5,h6')

    if not h:
      return self

    a = self.soup.new_tag('a', )
    a['href'] = self.url
    a['target'] = '_blank'
    a.string = self.url
    h.insert_after(a)
    a.wrap(self.soup.new_tag('p'))

    return self

  def page_save_clean(self):

    self.ii_clean = self._file_ii({ 'tipe' : 'clean' })
    util.mk_parent_dir(self.ii_clean)

    with open(self.ii_clean, 'w') as f:
      f.write(self.soup.prettify())

    return self

  def page_add(self):
    self.page.update({
      'uri' : { 
        'base'   : self.base_url,
        'remote' : self.url,
        'meta'   : self._file_ii_uri({ 'tipe' : 'meta', 'ext'   : 'txt' }),
        'script' : self._file_ii_uri({ 'tipe' : 'script', 'ext' : 'txt' }),
        'clean'  : self._file_ii_uri({ 'tipe' : 'clean' }),
        'cache'  : self._file_ii_uri(),
        'img'       : self._file_ii_uri({ 'tipe' : 'img' }),
        'img_clean' : self._file_ii_uri({ 'tipe' : 'img_clean' }),
      },
      'title' : self.title,
      'rid'   : self.rid,
    })

    if len(self.page):
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

  def in_load_site_yaml(self,ref={}):
    site = ref.get('site',self.site)

    [ lib, mod ] = self._site_libdir(site)
    site_yaml = os.path.join(lib,mod + '.yaml')

    if not os.path.isfile(site_yaml):
      return self

    d = self._yaml_data(site_yaml)
    self.sites[site] = d

    self.log(f'[in_load_site_yaml] loaded YAML for site: {site}' )
    return self

  def in_load_site_module(self,ref={}):
    site = ref.get('site',self.site)

    [ lib, mod ] = self._site_libdir(site)

    libs = [ lib ]
    mod_file = os.path.join(lib,mod + '.py')
    if not os.path.isfile(mod_file):
      return self

    # module name
    add_libs(libs)
    m = self.modules['sites'][site] = __import__(mod)

    if m:
      self.log(f'[in_load_site_module] loaded module for site: {site}' )
      p = self.page_obj_site = m.Page({ 
        'soup' : self.soup,
        'app'  : self,
      })

    return self

  def update_ii(self):
    self.page_ii_from_title()
    self.log(f'[load_soup] ii: {self.ii}')
    
    return self

###pu
  def parse_url_run(self,ref={}):
    tipes = util.qw('img img_clean')

    self                                                \
        .load_soup()                                    \
        .in_load_site_module()                          \
        .update_ii()                                    \
        .in_load_site_yaml()                            \
        .page_get_date()                                \
        .page_get_author()                              \
        .page_get_ii_full()                             \
        .db_save_url()                                  \
        .page_save_data({ 'tags' : 'meta,script,img' }) \
        .cmt(''' save image data => img.html''')        \
        .page_save_data_img()                           \
        .page_clean()                                   \
        .page_unwrap()                                  \
        .page_rm_empty()                                \
        .page_header_insert_url()                       \
        .page_save_clean()                              \
        .page_save_data_img({ 'tipe' : 'img_clean' })   \
        .page_do_imgs()                                 \
        .page_replace_links({ 'act' : 'rel_to_remote'}) \
        .load_soup_file_ii({                            \
            'tipes' : tipes                             \
        })                                              \
        .ii_replace_links({                             \
            'tipes' : tipes,                            \
            'act'  : 'remote_to_db',                    \
        })                                              \
        .page_save_clean()                              \
        .page_add()                                     \

    return self
  
  def parse_url(self,ref={}):
    self.url = ref.get('url','')
    self.ii  = ref.get('ii','')

    if not self.url or self.url == const.plh:
      return self

    u = urlparse(self.url)
    self.host = u.netloc.split(':')[0]
    self.base_url = u.scheme + '://' + u.netloc 
    self.site = util.get(self,[ 'hosts', self.host, 'site' ],'')

    hsts = self.hosts
    try:
      for pat in hsts.keys():
        for k in pat.split(','):
          if self.host.find(k) != -1:
            self.site = util.get(hsts,[ pat, 'site' ])
            if self.site:
              raise StopIteration

    except StopIteration:
      pass

    if not self.site:
      self.log(f'[WARN] no site for url: {self.url}')
      return self

    self.page = {}

    acts = ref.get('acts')
    if acts:
      if type(acts) is list:
        self.page['acts'] = acts
      elif type(acts) is str:
        self.page['acts'] = acts.split(',')

    self.page['tags'] = ref.get('tags')

    if (not ref.get('redo',0)):
      if self._site_skip() \
          or self._url_saved_fs(): 
        return self

    self.log('=' * 100)
    self.log(f'[parse_url] start: {self.url}')

    self.parse_url_run()

    return self

  def page_ii_from_title(self,ref={}):
    p = self.page_obj_site

    if self.ii:
      return self

    if util.obj_has_method(p, 'generate_ii'):
      p.generate_ii()
    else:
      if self.title:
        tt = self.title
        tt = re.sub(r'\s', '_', tt)
        ttl = cyrtranslit.to_latin(tt,'ru').lower()
        ttl = re.sub(r'[\W\']+', '', ttl)
        self.ii = ttl

    return self

  def page_get_ii_full(self,ref={}):
    self.page['ii_full'] = self._ii_full()
    return self

  def page_get_author(self,ref={}):
    p = self.page_obj_site
    if not p:
      return self

    p.get_author()

    aid = self.page.get('author_id','')
    f = aid.split(',')
    if f and len(f):
      self.page['author_id_first'] = f[0]

    return self

  def page_get_date(self,ref={}):
    p = self.page_obj_site
    if not p:
      return self

    p.get_date()

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

    file = self._file_ii({ 
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
              href = util.url_join(self.base_url,href)
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

  def _rid_free(self):
    db_file = self.url_db
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

    db_file = self.url_db
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
  def db_save_url(self, ref={}):
    url   = ref.get('url', self.url)
    title = ref.get('title', self.title)

    db_file = self.url_db
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    self.rid = self._rid_free()
    if self._url_saved_db(url):
      self.rid = self._rid_url()
      if not self._act('db_update'):
        return self

    insert = {
        'remote' : url,
        'rid'    : self.rid,
        'ii'     : self.ii,
        'site'   : self.site,
        'title'  : title,
    }

    kk = '''date title_h tags encoding author_id author_id_first ii_num ii_full'''
    for k in kk.split(' '):
      insert.update({ k : self.page.get(k) })

    d = {
      'db_file' : self.url_db,
      'table'   : 'urls',
      'insert'  : insert,
    }
    dbw.insert_dict(d)
    self.log(f'[db_save_url] url saved with rid {self.rid}')

    return self

  def _site_libdir(self,site=None):
    if not site:
      site = self.site

    a = [ self.in_dir, 'sites' ]
    a.extend(site.split('.'))
    mod = a[-1]
    del a[-1]
    lib  = '/'.join(a)

    return [ lib, mod ]

  def _site_skip(self,site=None):
    if not site:
      site = self.site

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

  def _cnf(self,key=None):
    val = util.get(self, [ 'cnf', key  ],0)
    return val

  def _url_saved_db(self,url=None):
    if not url:
      url = self.url
    rid = self._rid_url(url)
    return 0 if rid == None else 1

  def _url_saved_fs(self,url=None):
    if not url:
      url = self.url

    rid = self._rid_url(url)

    if rid == None:
      return 0

    self.ii_cache = self._file_ii({ 'rid' : rid })
    if os.path.isfile(self.ii_cache):
      return 1
    return 0

  def _rid_url(self,url=None):
    db_file = self.url_db
    conn = sqlite3.connect(db_file)
    c = conn.cursor()

    if not url:
      url = self.url

    q = '''SELECT rid FROM urls WHERE remote = ?'''
    c.execute(q,[url])
    rw = c.fetchone()

    return ( rw[0] if rw else None )

  def _img_ext(self,imgobj=None):
    map = {
       'JPEG'  : 'jpg',
       'PNG'   : 'png',
    }
    ext = map.get(imgobj.format,'jpg')
    return ext
     
  def _ii_full(self):
    date = self.page.get('date')
    site = self.site

    self.page['ii_num'] = ii_num = self._ii_num()

    a_f = self.page.get('author_id_first')
    a_fs = f'.{a_f}' if a_f else ''

    ii_full = f'{date}.site.{site}{a_fs}.{ii_num}.{self.ii}'

    return ii_full

  def _ii_num(self):

    ii_num = self.page.get('ii_num')
    if ii_num:
      return ii_num

    date = self.page.get('date')
    site = self.site

    a_f = self.page.get('author_id_first')
    a_fs = f'.{a_f}' if a_f else ''

    pattern = f'{date}.site.{site}{a_fs}.'

    db_file = self.url_db
    conn = sqlite3.connect(db_file)
    #conn.row_factory = sqlite3.Row
    c = conn.cursor()

    q = f'''SELECT 
                MAX(ii_num) 
            FROM urls 
                WHERE ( NOT remote = ? ) AND ii_full LIKE "{pattern}%"
         '''
    c.execute(q,[ self.url ])    
    rw = c.fetchone()
    if rw[0] is not None:
      ii_num = rw[0] + 1
    else:
      ii_num = 1

    conn.commit()
    conn.close()

    return ii_num

  def _img_local_uri(self, url):
    if not ( self.img_db and os.path.isfile(self.img_db) ):
      pass
    else:
      conn = sqlite3.connect(self.img_db)
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

    if not ( self.img_db and os.path.isfile(self.img_db) ):
      return 

    d = None

    conn = sqlite3.connect(self.img_db)
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
    if not ( self.img_db and os.path.isfile(self.img_db) ):
      pass
    else:
      conn = sqlite3.connect(self.img_db)
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

  def page_save_data(self,ref={}):
    ext  = ref.get('ext','txt')

    tag  = ref.get('tag',None)
    tags = ref.get('tags',[])

    tags_a = tags
    if type(tags) is str:
      tags_a = tags.split(',')
    for tag in tags_a:
      self.page_save_data({ 'tag' : tag, 'ext' : ext })

    if not tag:
      return self

    els = self.soup.select(tag)
    txt = []
    data_file = self._file_ii({ 'tipe' : tag, 'ext' : ext })
    for e in els:
      ms = str(e)
      txt.append(ms)
    with open(data_file, 'w') as f:
        f.write("\n".join(txt))
    return self

  def page_save_data_img(self,ref={}):
    tipe = ref.get('tipe','img')

    data_file_img = self._file_ii({ 
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
           img_remote = util.url_join(self.base_url, img_remote_rel)
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
      baseurl=self.base_url
    )

    soup = BeautifulSoup(h,'html5lib')
    h = soup.prettify()

    with open(data_file_img, 'w') as f:
        f.write(h)
    return self

  def page_do_imgs(self):
    if self._act('no_img'):
     return self

    site     = util.get(self,'site','')
    host     = util.get(self,'host','')
    base_url = util.get(self,'base_url','')
    ii       = util.get(self,'ii','')

    img_dir = self._dir_ii_img()

    j = 0
    els_img = self.soup.find_all("img")
    for el_img in els_img:
      j+=1
      caption = ''
      #if el_img.has_attr('alt'):
        #caption = el_img['alt']

      if el_img.has_attr('src'):
        src = el_img['src']
        rel_src = None
        u = urlparse(src)

        if not u.netloc:
          url = util.url_join(base_url,src)
          rel_src = src
        else:
          url = src

        get_img = 1
        img_saved = self._img_saved(url)
        if not self._act('get_img'):
          # image saved to fs && db
          if img_saved:
            idata = self._img_data({ 'url' : url })
            ipath = idata.get('path','')
            get_img = 0

###i
        if get_img:
          self.log(f"[page_do_imgs] Getting image: \n\t{url}")

          i = None
          resp = requests.get(url, stream = True)
          resp.raw.decoded_content = True

          i_tmp = { 
             'bare' : self._dir('tmp_img bs_img'),
             'png'  : self._dir('tmp_img bs_img.png'),
          }
          with open(i_tmp['bare'], 'wb') as lf:
            shutil.copyfileobj(resp.raw, lf)

          #resp.raw type is urllib3.response.HTTPResponse

          # Image class instance
          i = None
          try:
            i = Image.open(i_tmp['bare'])
            #i = Image.open(resp.raw)
          except UnidentifiedImageError:
            #with open(i_tmp, 'r') as lf:
              #a = lf.read()

            ct = resp.headers['content-type']
            if ct in [ 'image/svg+xml' ]:
              cairosvg.svg2png( 
                file_obj=open(i_tmp['bare'], "rb"),
                write_to=i_tmp['png']
              )
              i = Image.open(i_tmp['png'])
            
          if not i:
            self.log(f'FAIL[page_do_imgs] no Image.open instance: {url}')
            continue
            
          self.log(f'[page_do_imgs] Image format: {i.format}')
          iext = self._img_ext(i)

          dd = { 
            'url'  : url,
            'ext'  : iext,
          }
          if not img_saved:
            dd.update({ 'opts' : 'new' })

          idata = self._img_data(dd)

          img   = idata.get("img","")
          inum  = idata.get('inum','')
          ipath = idata.get('path','')

          self.log(f'[page_do_imgs] Local path: {idata.get("path","")}')
          if os.path.isfile(ipath):
            self.log(f'WARN[page_do_imgs] image file already exists: {img}')

          i.save(ipath)
          i.close()
          self.log(f'[page_do_imgs] Saved image: {img}')

          d = {
            'db_file' : self.img_db,
            'table'   : 'imgs',
            'insert' : {
              'url'        : url,
              'url_parent' : self.url,
              'img'        : img,
              'inum'       : inum,
              'ext'        : iext,
              'rootid'     : self.rootid,
              'proj'       : self.proj,
              'caption'    : caption,
            }
          }
          dbw.insert_dict(d)

        ipath_uri = Path(ipath).as_uri()
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

    if not self.url:
      urls = getattr(self,'urls',[]) 
      for d in urls:
        self.parse_url(d)

    else:
      self.parse_url(self.url)
    
    return self

  def main(self):

    self                  \
      .get_opt()          \
      .init_dirs()        \
      .init_db_urls()     \
      .init_tmpl()        \
      .mk_dirs()          \
      .load_yaml()        \
      .fill_vars()        \
      .parse()            \
      .render_page_list() \

BS({}).main()

#[method for method in dir(meta) if method.startswith('__') is False]
#https://code.activestate.com/recipes/577346-getattr-with-arbitrary-depth/
