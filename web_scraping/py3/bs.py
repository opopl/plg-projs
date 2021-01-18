
import requests
from bs4 import BeautifulSoup

import getopt,argparse
import sys,os
import yaml
import pathlib

class BS:
  # class attributes {
  usage='''
This script will parse input URL
'''

  # data
  data = {}

  # directories
  dirs = {}

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

    self \
      .init_dirs() \
      .mk_dirs()

    return self

  def init_dirs(self):
    if self.f_yaml:
      pp = pathlib.Path(self.f_yaml).resolve()
      dir = str(pp.parent)
      stem = pp.stem
      self.dirs['out'] = os.path.join(dir,'out',stem)
    
    self.dirs['html_bare'] = os.path.join(self.dirs['out'],'html','bare')

    return self

  def mk_dirs(self):
    for k,v in self.dirs.items():
      os.makedirs(v,exist_ok=True)

    return self

  def parse_yaml(self,f_yaml=''):
    with open(f_yaml) as f:
      d = yaml.full_load(f)
      urls = d.get('urls',[])
      for d in urls:
        self.parse_url(d)

    return self
  
  def parse_url(self,ref={}):
    url = ref.get('url','')
    ii  = ref.get('ii','')

    dt = { 
      'imgs' : [],
      'title' : '',
    }

    page = requests.get(url)
    c = page.content
    soup = BeautifulSoup(c,'html5lib')

    out_file_bare = os.path.join(self.dirs['out'],'html','bare')

    print({ 
        #'title' : soup.title.get_text(),
        'h1' : soup.h1.get_text(),
    })

    for img in soup.find_all("img"):
      d = {}
      for k in [ 'src', 'alt', 'data-src' ]:
        if img.has_attr(k):
          d[k] = img[k]
      print(d)
      print(img.string)

      dt['imgs'].append(d)

    self.data[url] = dt

    return self

  def main(self):
    self.get_opt()

    if not self.url:
      if self.f_yaml and os.path.isfile(self.f_yaml):
        self.parse_yaml(self.f_yaml)
      else:
        print('''Neither URL nor YAML provided, exiting''')
      exit()
    self.parse_url(self.url)

BS().main()

