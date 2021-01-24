
import requests
from bs4 import BeautifulSoup

import getopt,argparse
import sys,os
import yaml
import re

import sqlite3
import sqlparse

import html.parser

from pathlib import Path
from urllib.parse import urlparse
from urllib.parse import urljoin

from PIL import Image
from io import StringIO

#from jinja2 import Template

import jinja2
import shutil

import os,sys

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)

plg = os.environ.get('PLG')
add_libs([ os.path.join(plg,'projs','python','lib') ])
import Base.DBW as dbw
import Base.Util as util

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
    self.template_loader = jinja2.FileSystemLoader(searchpath=self.dirs['tmpl'])
    self.template_env = jinja2.Environment(loader=self.template_loader)

    return self

  def init_db_urls(self):
    print('[init_db_urls]')
  
    sql = '''
            CREATE TABLE IF NOT EXISTS urls (
                rid INTEGER UNIQUE,
                remote TEXT UNIQUE NOT NULL,
                date TEXT,
                title TEXT,
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
    print(f'[BS] Script location: {self.Script}')
    print(f'[BS] Template directory: {self.dirs["tmpl"]}')

    if self.f_yaml:
      pp = Path(self.f_yaml).resolve()
      dir = str(pp.parent)
      stem = pp.stem
      self.dirs['out'] = os.path.join(dir,'out',stem)
    
    self.dirs.update({ 
      'html'       : os.path.join(self.dirs['out'],'html'),
      'tex_out'    : os.path.join(self.dirs['out'],'tex'),
    })

    return self

  def mk_dirs(self):
    for k,v in self.dirs.items():
      os.makedirs(v,exist_ok=True)

    return self

  def load_yaml(self, f_yaml=None):
    if not f_yaml:
      f_yaml = self.f_yaml

    if f_yaml and os.path.isfile(f_yaml):
      with open(f_yaml) as f:
        d = yaml.full_load(f)
        for k,v in d.items():
          setattr(self,k,v)

    return self

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
    type = ref.get('type','cache')
    ext  = ref.get('ext','html')
    rid  = ref.get('rid',self.rid)

    ii_file = os.path.join(self._dir_ii({ 'rid' : rid }),f'{type}.{ext}')
    return ii_file

  def url_load_content(self,ref={}):
    if self._act('fetch'):
      self.url_fetch()
      return self

    if os.path.isfile(self.ii_cache):
      with open(self.ii_cache,'r') as f:
        self.content = f.read()
    else:
        self.url_fetch()

    return self

  def url_fetch(self,ref={}):
    url = ref.get('url',self.url)

    if self.page.get('fetched'):
      return self

    r = requests.get(url)

    encoding = 'utf-8'
    if 'charset' in r.headers.get('content-type', '').lower():
      encoding = r.encoding
    self.page['encoding'] = encoding

    self.content = r.content

    util.mk_parent_dir(self.ii_cache)
    with open(self.ii_cache, 'wb') as f:
      f.write(self.content)

    self.page['fetched'] = 1

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

    self.title = self.soup.select_one('head > title').string.strip("\'\"")

    print(f'[load_soup] rid: {self.rid}, title: {self.title}')

    return self

  def page_clean(self):
    site = util.get(self,'site','')
    ii   = util.get(self,'ii','')

    clean = util.get(self,[ 'sites', site, 'clean' ],[])

    for c in clean:
      els_clean = self.soup.select(c)
      for el in els_clean:
        el.decompose()

    return self

  def page_header_insert_url(self):
    h = self.soup.select_one('h1,h2,h3,h4,h5,h6')

    a = self.soup.new_tag('a', )
    a['href'] = self.url
    a['target'] = '_blank'
    a.string = self.url
    h.insert_after(a)
    a.wrap(self.soup.new_tag('p'))

    return self

  def page_save_clean(self):

    self.ii_clean = self._file_ii({ 'type' : 'clean' })
    util.mk_parent_dir(self.ii_clean)

    with open(self.ii_clean, 'w') as f:
      f.write(self.soup.prettify())

    return self

  def page_add(self):
    self.page.update({
      'uri' : { 
        'base'   : self.base_url,
        'remote' : self.url,
        'meta'   : self._file_ii_uri({ 'type' : 'meta', 'ext'   : 'txt' }),
        'script' : self._file_ii_uri({ 'type' : 'script', 'ext' : 'txt' }),
        'clean'  : self._file_ii_uri({ 'type' : 'clean' }),
        'cache'  : self._file_ii_uri(),
        'img'       : self._file_ii_uri({ 'type' : 'img', 'ext'       : 'htm' }),
        'img_clean' : self._file_ii_uri({ 'type' : 'img_clean', 'ext' : 'htm' }),
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

  def in_load_site_module(self,ref={}):
    site = ref.get('site',self.site)

    a = [ self.in_dir, 'sites' ]
    a.extend(site.split('.'))
    mod = a[-1]
    del a[-1]
    lib  = '/'.join(a)
    libs = [ lib ]
    mod_file = os.path.join(lib,mod + '.py')
    if not os.path.isfile(mod_file):
      return self

    # module name
    add_libs(libs)
    m = self.modules['sites'][site] = __import__(mod)

    if m:
      print(f'[in_load_site_module] loaded module for site: {site}' )
      p = self.page_obj_site = m.Page({ 
        'soup' : self.soup,
        'app'  : self,
      })

    return self
  
  def parse_url(self,ref={}):
    self.url = ref.get('url','')
    self.ii  = ref.get('ii','')

    u = urlparse(self.url)
    self.host = u.netloc.split(':')[0]
    self.base_url = u.scheme + '://' + u.netloc 
    self.site = util.get(self,[ 'hosts', self.host, 'site' ],'')

    self.page = {}

    acts = ref.get('acts')
    if acts:
      if type(acts) is list:
        self.page['acts'] = acts
      elif type(acts) is str:
        self.page['acts'] = acts.split(',')

    self.page['tags'] = ref.get('tags')

    if (not ref.get('reparse',0)) and (not ref.get('fail',0)):
      if self._site_skip() \
          or self._url_saved_fs(): 
        return self

    self                                                \
        .load_soup()                                    \
        .in_load_site_module()                          \
        .page_get_date()                                \
        .page_get_author()                              \
        .page_get_ii_full()                             \
        .db_save_url()                                  \
        .page_save_data({ 'tags' : 'meta,script,img' }) \
        .page_save_data_img()                           \
        .page_clean()                                   \
        .page_do_imgs()                                 \
        .page_save_data_img({ 'type' : 'img_clean'})    \
        .page_replace_links()                           \
        .page_unwrap()                                  \
        .page_rm_empty()                                \
        .page_header_insert_url()                       \
        .page_save_clean()                              \
        .page_add()                                     \

    return self

  def page_get_ii_full(self,ref={}):
    self.page['ii_full'] = self._ii_full()
    return self

  def page_get_author(self,ref={}):
    p = self.page_obj_site
    if not p:
      return

    p.get_author()

    aid = self.page.get('author_id','')
    f = aid.split(',')
    if f and len(f):
      self.page['author_id_first'] = f[0]

    return self

  def page_get_date(self,ref={}):
    p = self.page_obj_site
    if not p:
      return
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

  def page_replace_links(self):
    j=0
    next = self.soup.html
    while 1:
      if not next:
        break 
      j+=1
      next = next.find_next()
      if hasattr(next,'name') and next.name == 'a':
        if next.has_attr('href'):
          href = next['href']
          u = urlparse(href)
          if not u.netloc:
            href = urljoin(self.base_url,href)
            next['href'] = href
          next['target'] = '_blank'

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
        'title'  : title,
        'ii'     : self.ii,
        'site'   : self.site,
    }

    kk = '''tags encoding author_id author_id_first ii_num ii_full'''
    for k in kk.split(' '):
      insert.update({ k : self.page.get(k) })

    if self.page['date']:
      insert.update({ 'date' : self.page['date'] })

    d = {
      'db_file' : self.url_db,
      'table'   : 'urls',
      'insert'  : insert,
    }
    dbw.insert_dict(d)
    print(f'[db_save_url] url saved with rid {self.rid}')

    return self

  def _site_skip(self,site=None):
    if not site:
      site = self.site

    inc = self.list_hosts_inc

    skip = 0 if site in inc else 1
    return skip

  def _act(self,key=None):
    acts = self.page.get('acts',[])
    if not acts:
      return 0

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

  def _img_data(self, url, ext='jpg'):
    d = {}
    if not ( self.img_db and os.path.isfile(self.img_db) ):
      pass
    else:
      conn = sqlite3.connect(self.img_db)
      c = conn.cursor()
  
      c.execute('''SELECT img, inum FROM imgs WHERE url = ?''',[ url ])
      rw = c.fetchone()

      if rw:
        img = rw[0]
        inum = rw[1]
      else:
        c.execute('''SELECT MAX(inum) FROM imgs''')
        rw = c.fetchone()
        inum = rw[0]
        inum += 1
        img = f'{inum}.{ext}'

      ipath = os.path.join(self.img_root, img)

      d.update({ 
        'inum' : inum,
        'img'  : img,
        'path' : ipath,
        'uri'  : Path(ipath).as_uri()
      })

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
    data_file = self._file_ii({ 'type' : tag, 'ext' : ext })
    for e in els:
      ms = str(e)
      txt.append(ms)
    with open(data_file, 'w') as f:
        f.write("\n".join(txt))
    return self

  def page_save_data_img(self,ref={}):
    type = ref.get('type','img')

    #if type == 'img_clean':
      #return self
    print(type)

    data_file_img = self._file_ii({ 
      'type' : type, 
      'ext'  : 'htm' 
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
            if type == 'img':
              img_remote_rel = el[k] 
              img_remote = urljoin(self.base_url, img_remote_rel)
              img_local = self._img_local_uri(img_remote)
  
              itm['uri'][k] = img_remote_rel
              if img_local:
                itm['uri_local'][k] = img_local
            #elif:
              #img_local = el[k]

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

    t = self.template_env.get_template("img.t.htm")
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
    for el_img in self.soup.find_all("img"):
      j+=1
      caption = ''
      #if el_img.has_attr('alt'):
        #caption = el_img['alt']

      if el_img.has_attr('src'):
        src = el_img['src']
        rel_src = None
        u = urlparse(src)

        if not u.netloc:
          url = urljoin(base_url,src)
          rel_src = src
        else:
          url = src

        if self._img_saved(url):
          idata = self._img_data(url)
          ipath = idata.get('path','')
          pass
        else:
          print(f"[page_do_imgs] Getting image: \n\t{url}")
          try:
            i = None
            try:
              i = Image.open(requests.get(url, stream = True).raw)
            except:
              print(f'FAIL[page_do_imgs] Image.open: {url}')
              print(f'FAIL[page_do_imgs] Image.open failure: {sys.exc_info()[0]}')
              continue

            if not i:
              print(f'FAIL[page_do_imgs] no Image.open instance: {url}')
              continue
            
            print(f'[page_do_imgs] Image format: {i.format}')
            iext = self._img_ext(i)
            idata = self._img_data(url,iext)

            img   = idata.get("img","")
            inum  = idata.get('inum','')
            ipath = idata.get('path','')

            print(f'[page_do_imgs] Local path: {idata.get("path","")}')
            if os.path.isfile(ipath):
              print(f'WARN[page_do_imgs] image file already exists: {img}')
            else:
              i.save(ipath)
              print(f'[page_do_imgs] Saved image: {img}')

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
          except:
            print(f'WARN[page_do_imgs] Image.open exception: {url}')
            raise

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

    t = self.template_env.get_template("list.t.htm")
    h = t.render(pages=self.pages)

    h_file = os.path.join(self.dirs['html'],'list.html')

    with open(h_file, 'w') as f:
        f.write(h)

    h_uri = Path(h_file).as_uri()
    print(f'[BS] list: {h_uri}')

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
