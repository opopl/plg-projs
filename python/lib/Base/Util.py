
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

import re

MATCH_ALL = r'.*'


#https://stackoverflow.com/questions/31958637/beautifulsoup-search-by-text-inside-a-tag
def bs_like(string):
    """
    Return a compiled regular expression that matches the given
    string with any prefix and postfix, e.g. if string = "hello",
    the returned regex matches r".*hello.*"
    """
    string_ = string
    if not isinstance(string_, str):
        string_ = str(string_)
    regex = MATCH_ALL + re.escape(string_) + MATCH_ALL
    return re.compile(regex, flags=re.DOTALL)

#https://stackoverflow.com/questions/31958637/beautifulsoup-search-by-text-inside-a-tag
def bs_find_by_text(soup, text, tag, **kwargs):
    """
    Find the tag in soup that matches all provided kwargs, and contains the
    text.

    If no match is found, return None.
    If more than one match is found, raise ValueError.
    """
    elements = soup.find_all(tag, **kwargs)
    matches = []
    for element in elements:
        if element.find(text=bs_like(text)):
            matches.append(element)
    if len(matches) > 1:
        raise ValueError("Too many matches:\n" + "\n".join(matches))
    elif len(matches) == 0:
        return None
    else:
        return matches[0]

def mk_parent_dir(file):
  p = str(Path(file).parent)
  os.makedirs(p,exist_ok=True)

def call(obj, subn, args = []):
  res = None

  if type(subn) in [list]:
    for a in subn:
      sub  = a.pop(0)
      args = a.pop(0) if len(a) else []
      call(obj,sub,args)

  elif type(subn) in [str]:
    if subn in dir(obj):
      sub = getattr(obj,subn)
      if callable(sub):
        res = sub(*args)

  return res

def mk_dirname(file):
  os.makedirs(Path(file).parent.as_posix(),exist_ok=True)

def keys(dict={}):
  return list(dict.keys())

def url_parse(url,opts={}):
  u = urlparse(url)

  d = {}
  host = u.netloc.split(':')[0]

  scheme = u.scheme 
  if not u.scheme:
    scheme = 'http'
    m = re.match(r'^[/]+(.*)$', url)
    if m:
      url = m.group(1)
    if u.netloc:
      url = scheme + '://' + url

  baseurl = ''
  if scheme and u.netloc:
    baseurl = scheme + '://' + u.netloc

  d = {
    'scheme'  : scheme,
    'path'    : u.path,
    'netloc'  : u.netloc,
    'params'  : u.params,
    'query'   : u.query,
    'host'    : host,
    'baseurl' : baseurl,
    'url'     : url,
  }

  if get(opts,'rm_query'):
    d['url'] = urljoin(baseurl, d['path'])

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

def url2base(base,url):
  u = url_parse(url)
  if not u['netloc']:
    url = url_join(base,url)

  u = url_parse(url)
  url = u['url']
  #if not u['scheme']:
    #url = re.sub(r'^/*', r'', url)
    #url = f'https://{url}'

  return url

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
          if obj is None:
            obj = default
        else:
          obj = default
          break
      elif isinstance(obj,object):
        if hasattr(obj,k):
          obj = getattr(obj, k)
          if obj is None:
            obj = default
        else:
          obj = default
          break
    return obj

def var_type(x):
    typ = None

    if type(x) is str:
      typ = 'str'
    elif type(x) is int:
      typ = 'int'
    elif type(x) is list:
      typ = 'list'
    elif type(x) is dict:
      typ = 'list'
    elif type(x) is object:
      typ = 'object'

    return typ

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
