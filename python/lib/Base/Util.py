
import os
import re
import sys

from pathlib import Path
import pathlib

from urllib.parse import urlparse
from urllib.parse import urljoin

from url_normalize import url_normalize
import datetime
import shutil

def mk_parent_dir(file):
  p = str(Path(file).parent)
  os.makedirs(p,exist_ok=True)

def url_parse(url):
  u = urlparse(url)

  d = {}
  host = u.netloc.split(':')[0]
  baseurl = u.scheme + '://' + u.netloc

  d = {
    'scheme'  : u.scheme,
    'path'    : u.path,
    'netloc'  : u.netloc,
    'params'  : u.params,
    'query'   : u.query,
    'host'    : host,
    'baseurl' : baseurl,
  }

  return d

def strip(s):
  s = s.strip("\'\"\n\t ")
  return s

def obj_methods(obj):
  methods = [m for m in dir(obj) if callable(getattr(obj, m)) ]
  return methods

def obj_has_method(obj, method):
  has = 1 if method in obj_methods(obj) else 0
  return has

def which(name):
  return shutil.which(name)

def now(fmt='%d-%m-%Y %H:%M:%S'):
  now = datetime.datetime.now().strftime(fmt)
  return now

def url_join(base,rel):
  url = urljoin(base,rel)
  url = url_normalize(url)

  return url

def qw(s):
  a = s.split(' ')
  return a

def get(obj, path, default = None):
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

def uniq(lst=[]):
    lst = list(set(lst))
    return lst

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)

def readarr(dat_file, opts={}):
    splitsep = opts.get('sep', re.compile(r'\s+'))

    vars = []
    if not (dat_file and os.path.isfile(dat_file)):
      return []

    with open(dat_file,'r') as f:
      lines = f.readlines()

    for line in lines:
      line = line.strip()
      if re.match(r'^#',line) or (len(line) == 0):
        continue

      F = re.split(splitsep, line)
      vars.extend(F)
      vars = uniq(vars)

    return vars
