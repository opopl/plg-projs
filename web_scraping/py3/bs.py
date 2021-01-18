
import requests
from bs4 import BeautifulSoup

import getopt,argparse
import sys,os
import yaml

usage='''
This script will parse input URL
'''

parser = argparse.ArgumentParser(usage=usage)

parser.add_argument("-u", "--url", help="input URL",default="")
parser.add_argument("-y", "--f_yaml", help="input YAML file",default="")

args = parser.parse_args()
data = {}

if len(sys.argv) == 1:
  parser.print_help()
  sys.exit()

url = args.url
f_yaml = args.f_yaml

def parse_yaml(f_yaml=''):
  with open(f_yaml) as f:
    d = yaml.full_load(f)
    urls = d.get('urls',[])
    for d in urls:
      url = d.get('url','') 
      parse_url(url)

def parse_url(url):
  page=requests.get(url)
  c = page.content
  soup = BeautifulSoup(c,'html5lib')

  print({ 
      #'title' : soup.title.get_text(),
      'h1' : soup.h1.get_text(),
  })

def main():

  if not url:
    if f_yaml and os.path.isfile(f_yaml):
      parse_yaml(f_yaml)
    else:
      print('''Neither URL nor YAML provided, exiting''')
    exit()
  parse_url(url)

main()

