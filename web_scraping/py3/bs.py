
import requests
from bs4 import BeautifulSoup

import getopt,argparse
import sys,os
import yaml
import re

import sqlite3
import sqlparse

from pathlib import Path
from urllib.parse import urlparse
from urllib.parse import urljoin

from PIL import Image
from io import StringIO

import shutil

#[method for method in dir(meta) if method.startswith('__') is False]

  #https://code.activestate.com/recipes/577346-getattr-with-arbitrary-depth/

def mk_parent_dir(file):
  p = str(Path(file).parent)
  os.makedirs(p,exist_ok=True)

def g(obj, path, default = None):
    if type(path) is str:
      keys = path.split(".")
    elif type(path) is list:
      keys = path

    if not keys:
      return default

    for k in keys:
      if not obj:
        obj = default
        break
      if isinstance(obj,dict):
        if k in obj:
          obj = obj.get(k)
        else:
          obj = default
          break
      elif isinstance(obj,object):
        if hasattr(obj,k):
          obj = getattr(obj, k)
        else:
          obj = default
          break
    return obj

class BS:
  # class attributes {
  usage='''
This script will parse input URL
'''

  # data
  data = {}

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

  # input YAML file
  f_yaml = None

  # input URL
  url = None

  # output directory
  out_dir = None

  #command-line options
  oa = None

  # tex lines
  tex_lines = []

  img_db = None

  # end: attributes }

  def __init__(self,args={}):
    self.img_root = os.environ.get('IMG_ROOT')

    for k, v in args.items():
      self.k = v

    if self.img_root:
      self.img_db = os.path.join(self.img_root,'img.db')

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

  def init_dirs(self):
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

  def load_yaml(self,f_yaml=''):
    with open(f_yaml) as f:
      d = yaml.full_load(f)
      for k,v in d.items():
        setattr(self,k,v)

    return self

  def _dir_ii(self):
    ii = self.ii
    return os.path.join(self.dirs['html'],'ii',ii)

  def _dir_ii_img(self):
    img_dir = os.path.join(self._dir_ii(),'img')
    if not os.path.isdir(img_dir):
      os.makedirs(img_dir,exist_ok=True)
    return img_dir

  def _file_ii_txt(self,id):
    txt_file = os.path.join(self._dir_ii(),id + '.txt')
    return txt_file

  def _file_ii_html(self,type):
    ii_file = os.path.join(self._dir_ii(),type + '.html')
    return ii_file

  def load_soup(self,ref={}):
    url = ref.get('url',self.url)
    ii  = ref.get('ii',self.ii)

    ii_cached = self._file_ii_html('cache')
    if os.path.isfile(ii_cached):
      with open(ii_cached,'r') as f:
        self.content = f.read()
    else:
      page = requests.get(url)
      self.content = page.content

      mk_parent_dir(ii_cached)
      with open(ii_cached, 'wb') as f:
        f.write(self.content)

    self.soup = BeautifulSoup(self.content,'html5lib')

    return self

  def do_clean(self):
    site = g(self,'site','')
    ii   = g(self,'ii','')

    clean = g(self,[ 'sites', site, 'clean' ],[])

    for c in clean:
      #s = c.split('.')
      #tag = s.pop(0)
      #classes = s
      #els_clean = self.soup.findAll(tag,classes)
      els_clean = self.soup.select(c)
      for el in els_clean:
        el.decompose()

    return self

  def save_clean(self):

    ii_clean = self._file_ii_html('clean')
    mk_parent_dir(ii_clean)

    print("\t" + Path(ii_clean).as_uri())

    with open(ii_clean, 'w') as f:
      f.write(self.soup.prettify())

    return self
  
  def parse_url(self,ref={}):
    self.url = ref.get('url','')
    self.ii  = ref.get('ii','')

    u = urlparse(self.url)
    self.host = u.netloc.split(':')[0]
    self.base_url = u.scheme + '://' + u.netloc 
    self.site = g(self,[ 'hosts', self.host, 'site' ],'')

    self             \
        .load_soup() \
        .do_meta()   \
        .do_clean()  \
        .do_unwrap() \
        .rm_empty() \
        .do_imgs()   \
        .save_clean()

    return self

  def rm_empty(self):
    all = self.soup.find_all(True)
    while 1:
      el = all.pop(0)
      if el.name == 'img':
        continue

      if len(el.get_text(strip=True)) == 0:
        el.decompose()
      #txt = el.string.strip()
      #if not txt and not len(list(el.children)):
        #el.decompose()
      if not len(all):
        break
    return self

  def do_unwrap(self):
    while 1:
      div = self.soup.select_one('div')
      if not div:
        break
      div.unwrap()
    return self

  def _img_ext(self,imgobj=None):
    map = {
       'JPEG'  : 'jpg'
    }
    ext = map.get(imgobj.format,'jpg')
    return ext

  def _img_path(self, url, ext='jpg'):
    if not ( self.img_db and os.path.isfile(self.img_db) ):
      pass
    else:
      conn = sqlite3.connect(self.img_db)
      c = conn.cursor()
  
      c.execute('''SELECT img FROM imgs WHERE url = ?''',[ url ])
      rw = c.fetchone()

      if not rw:
        c.execute('''SELECT MAX(inum) FROM imgs''')
        rw = c.fetchone()
        inum = rw[0]
        inum += 1
        img = f'{inum}.{ext}'
      else:
        img = rw[0]

      ipath = os.path.join(self.img_root, img)
      return ipath

  def _img_saved(self,url):
    ok = 0
    if not ( self.img_db and os.path.isfile(self.img_db) ):
      pass
    else:
      conn = sqlite3.connect(self.img_db)
      c = conn.cursor()

      c.execute('''SELECT inum FROM imgs WHERE url = ?''',[ url ])
      rw = c.fetchone()
      if not rw:
        c.execute('''SELECT MAX(inum) FROM imgs''')
        rw = c.fetchone()
        inum = rw[0]

      conn.commit()
      conn.close()

    return ok

  def do_css(self):
    return self

  def do_meta(self):
    meta = self.soup.select("meta")
    txt = []
    meta_file = self._file_ii_txt('meta')
    for m in meta:
      ms = str(m)
      txt.append(ms)
    with open(meta_file, 'w') as f:
        f.write("\n".join(txt))
    return self

  def do_imgs(self):
    site     = g(self,'site','')
    host     = g(self,'host','')
    base_url = g(self,'base_url','')
    ii       = g(self,'ii','')

    img_dir = self._dir_ii_img()
    for img in self.soup.find_all("img"):
      if img.has_attr('src'):
        src = img['src']
        u = urlparse(src)
        if not u.netloc:
          url = urljoin(base_url,src)
        else:
          url = src

        if self._img_saved(url):
          pass
        else:
          print(f"Getting image: \n\t{url}")
          #import pdb; pdb.set_trace()
          try:
            i = Image.open(requests.get(url, stream = True).raw)
            if not i:
              print(f'[Image.open] FAIL: {url}')
              continue
            
            print(f'Image format: {i.format}')
            ipath = self._img_path(url,self._img_ext(i))

            print(f'Local path: {ipath}')
            #i.save(ipath)
          except:
            print(f'[Image.open] exception: {url}')
            raise

    return self

  def parse(self):
    if not self.url:
      if self.f_yaml and os.path.isfile(self.f_yaml):
        self.load_yaml(self.f_yaml)

      urls = getattr(self,'urls',[]) 
      for d in urls:
        self.parse_url(d)

    else:
      self.parse_url(self.url)
    
    return self

  def main(self):

    self           \
      .get_opt()   \
      .init_dirs() \
      .mk_dirs()   \
      .parse()

BS({}).main()

