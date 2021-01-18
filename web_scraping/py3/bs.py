
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
f_yaml = args.yaml

if not url:
  print('URL not provided!')
  exit()

page=requests.get(url)
c = page.content
soup = BeautifulSoup(c,'html5lib')

soup.html.find_all('img').get_text()
