
import requests
from bs4 import BeautifulSoup

import getopt,argparse
import sys,os
import yaml
import pathlib
from urllib.parse import urlparse

  #https://code.activestate.com/recipes/577346-getattr-with-arbitrary-depth/
def m_getattr(obj, attr, default = None):
    """
    Get a named attribute from an object; multi_getattr(x, 'a.b.c.d') is
    equivalent to x.a.b.c.d. When a default argument is given, it is
    returned when any attribute in the chain doesn't exist; without
    it, an exception is raised when a missing attribute is encountered.

    """
    attributes = attr.split(".")
    for i in attributes:
        try:
            obj = getattr(obj, i)
            print(obj)
        except AttributeError:
            if default:
                return default
            else:
                raise
    return obj

def m_get(dict, path, default = None):
    keys = path.split(".")
    for k in keys:
      dict = dict.get(k,default)
    return dict

class BS:
  # class attributes {
  usage='''
This script will parse input URL
'''

  # data
  data = {}

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

  # end: attributes }

  def __init__(self,args={}):
    for k, v in args.items():
      self.k = v

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
      pp = pathlib.Path(self.f_yaml).resolve()
      dir = str(pp.parent)
      stem = pp.stem
      self.dirs['out'] = os.path.join(dir,'out',stem)
    
    self.dirs.update({ 
      'html'       : os.path.join(self.dirs['out'],'html'),
      'html_cache' : os.path.join(self.dirs['out'],'html','cache'),
      'html_clean' : os.path.join(self.dirs['out'],'html','clean'),
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

    print(getattr(self,'hosts',{}))
    print(getattr(self,'sites',{}))
    print(m_getattr(self,'sites.strana.clean',{}))

    return self

  def _file_ii_html(self,ii,type):
    ii_file = os.path.join(self.dirs['html'],type,ii + '.html')
    return ii_file
  
  def parse_url(self,ref={}):
    url = ref.get('url','')
    ii  = ref.get('ii','')

    u = urlparse(url)
    host = u.netloc.split(':')[0]
    print(host)

    dt = { 
      'imgs' : [],
      'title' : '',
    }

    ii_cached = self._file_ii_html(ii,'cache')

    if os.path.isfile(ii_cached):
      with open(ii_cached,'r') as f:
        self.content = f.read()
    else:
      page = requests.get(url)
      self.content = page.content

      with open(ii_cached, 'wb') as f:
        f.write(self.content)

    soup = BeautifulSoup(self.content,'html5lib')

    #print({ 
        ##'title' : soup.title.get_text(),
        #'h1' : soup.h1.get_text(),
    #})

    for img in soup.find_all("img"):
      d = {}
      for k in [ 'src', 'alt', 'data-src' ]:
        if img.has_attr(k):
          d[k] = img[k]
      #print(d)
      #print(img.string)

      dt['imgs'].append(d)

    self.data[url] = dt

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

BS().main()

