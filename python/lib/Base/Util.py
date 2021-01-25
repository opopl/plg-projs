
import pathlib
import os
from pathlib import Path

from urllib.parse import urlparse
from urllib.parse import urljoin

from url_normalize import url_normalize

def mk_parent_dir(file):
  p = str(Path(file).parent)
  os.makedirs(p,exist_ok=True)

def url_parse(url):
  u = urlparse(url)

  return u

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
