
import requests
from bs4 import BeautifulSoup

import getopt,argparse
import sys,os
import yaml

class BS:
  usage='''
This script will parse input URL
'''
  f_yaml = None
  url = None

  def __init__(self,args={}):
    for k, v in args.items():
      self.k = v

  def getopt(self):
    self.parser = argparse.ArgumentParser(usage=self.usage)
    
    self.parser.add_argument("-u", "--url", help="input URL",default="")
    self.parser.add_argument("-y", "--f_yaml", help="input YAML file",default="")
    
    self.oa = self.parser.parse_args()

    if len(sys.argv) == 1:
      self.parser.print_help()
      sys.exit()

    self.url = self.oa.url
    self.f_yaml = self.oa.f_yaml

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

    page = requests.get(url)
    c = page.content
    soup = BeautifulSoup(c,'html5lib')

    print({ 
        #'title' : soup.title.get_text(),
        'h1' : soup.h1.get_text(),
    })

    return self

  def main(self):
    self.getopt()

    if not self.url:
      if self.f_yaml and os.path.isfile(self.f_yaml):
        self.parse_yaml(self.f_yaml)
      else:
        print('''Neither URL nor YAML provided, exiting''')
      exit()
    self.parse_url(self.url)

BS().main()

