
import os
import re
import sys

import ast
import copy

from pathlib import Path
import pathlib

import posixpath

from urllib.parse import urlparse
from urllib.parse import urljoin

from url_normalize import url_normalize
import datetime
import shutil

import subprocess
import shlex
from subprocess import Popen, PIPE

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

def dict2list(dct={}, keys=[]):
  kk = list(filter(lambda x: x in dct,keys))
  def _val(x):
    return dct.get(x)

  lst = list(map(lambda x: _val(x),kk))
  return lst

def dictnew(path='', val='', sep='.'):
  '''
    d = dictnew('a.b.c.d',value)
    d = dictnew('a/b/c/d',value,sep='/')
  '''
  def _dictnew(dct, path, val):
    while path.startswith(sep):
      path = path[1:]
    parts = path.split(sep, 1)
    if len(parts) > 1:
        branch = dct.setdefault(parts[0], {})
        _dictnew(branch, parts[1], val)
    else:
        if not parts[0] in dct:
          dct[parts[0]] = val

  d = {}
  _dictnew(d,path,val)
  return d

def call(obj, subn, args_in = []):
  res = None

  args = args_in

  if type(subn) in [list]:
    for a in subn:
      if type(a) in [list]:
        sub  = a.pop(0)
        args_ = a.pop(0) if len(a) else args_in
        call(obj,sub,args_)

      elif type(a) in [str]:
        sub  = a
        call(obj,sub,args)

  elif type(subn) in [str]:
    if subn in dir(obj):
      sub = getattr(obj,subn)
      if callable(sub):
        if type(args) in [list]:
          res = sub(*args)
        elif type(args) in [dict]:
          res = sub(**args)

  return res

def mk_dirname(file):
  os.makedirs(Path(file).parent.as_posix(),exist_ok=True)

def keys(dict={}):
  return list(dict.keys())

def url_parse_query(query=''):
  if not query:
    return {}

  d = {}

  query_split = query.split('&')
  for piece in query_split:
    m = re.match(r'^(\S+)=(\S+)$',piece)
    if not m:
      continue

    key   = m.group(1)
    value = m.group(2)
    d.update({ key : value })

  return d

def url_parse(url,opts={}):
  d = {}

  if get(opts,'rm_@'):
    m = re.match(r'^(?P<scheme>\w+://)(?P<login>\w+):(?P<pwd>\S+)@(?P<host>[^\s/]+)(?P<end>.*)$',url)
    if m:
      url = ''.join([ m.group('scheme'), m.group('host'), m.group('end') ])
      d.update({
         'login' : m.group('login'),
         'pwd'   : m.group('pwd'),
      })

  u = urlparse(url)

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

  query_p = url_parse_query(u.query)

  basename = posixpath.basename(u.path)

  port = ''
  try:
    port = u.port or ''
  except:
    pass

  d = {
    'scheme'   : scheme,
    'path'     : u.path,
    'port'     : port,
    'fragment' : u.fragment,
    'netloc'   : u.netloc,
    'params'   : u.params,
    'query'    : u.query,
    'query_p'  : query_p,
    'host'     : host,
    'baseurl'  : baseurl,
    'basename' : basename,
    'url'      : url,
  }

  rm_query = get(opts,'rm_query') or 0
  rm_query = int(rm_query)
  if rm_query:
    d['url'] = urljoin(baseurl, d['path'])

  return d

def list_strip(lst=[],s='\n'):

  return list(map(lambda x: x.strip(s), lst))

def strip(s):
  s = s.strip("\'\"\n\t ")
  return s

def obj_update(**kwargs):
  keys     = get(kwargs,'keys',[])
  defaults = get(kwargs,'defaults',{})
  default  = get(kwargs,'default')

  dest     = get(kwargs,'dest',{})
  source   = get(kwargs,'source',{})

  for k in keys:
    df      = get(defaults,k,default)
    dest[k] = get(source,k,df)

  return dest

def dict_none_rm(obj):
  keys = list(obj.keys())
  for k in keys:
    v = obj.get(k)
    if v == None:
      del obj[k]
    elif type(v) in [dict]:
      v = dict_none_rm(v)
      obj[k] = v

  return obj

def dict_none2str(obj,keys = []):
  if not len(keys):
    keys = list(obj.keys())

  for k in keys:
    v = obj.get(k)
    if v == None:
      obj[k] = ''

  return obj

def dict_str2int(obj,keys = []):
  if not len(keys):
    keys = list(obj.keys())

  for k in keys:
    v = obj.get(k)
    if v != None and type(v) in [str]:
      v = int(v)
      obj[k] = v

  return obj

def obj_methods(obj):
  methods = [m for m in dir(obj) if callable(getattr(obj, m)) ]
  return methods

def obj_has_method(obj, method):
  has = 1 if method in obj_methods(obj) else 0
  return has

# https://stackoverflow.com/questions/11495783/redirect-subprocess-stderr-to-stdout

# p = subprocess.Popen(['git', 'ls', old_path], stdout=PIPE, stderr=PIPE)
# stdout, stderr = p.communicate()

def git_move(old='',new=''):
  if not git_has(old):
    return

  cmd = f'git mv {old} {new}'
  r = shell({ 'cmd' : cmd })
  out  = r.get('out')
  code = r.get('code')
  if code:
    return

  return True

def git_add(file=''):
  if not file:
    return

  cmd = f'git add {file}'

  r = shell({ 'cmd' : cmd })
  out  = r.get('out')
  code = r.get('code')
  if code or len(out):
    return

  return True

def git_has(file=''):
  if not file:
    return False

  cmd = f'git ls {file}'

  r = shell({ 'cmd' : cmd })
  out  = r.get('out')
  code = r.get('code')
  if code or not len(out):
    return False

  return True

#def shell_join(ref={}):
  #cmd = ref.get('cmd','')

  #p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT )
  #out = []
  #for line_raw in p.stdout.readlines():
    #line = line_raw.decode('utf-8').strip()
    #out.append(line)

  #rtval = p.wait()

  #return { 'out' : out, 'code' : rtval }

def shell(ref={}):
  cmd = ref.get('cmd','')

  p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT )

  out = []
  for line_raw in p.stdout.readlines():
    line = line_raw.decode('utf-8').strip()
    out.append(line)

  code = p.wait()

  return {
    'out'  : out,
    'code' : code,
  }

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

def find(ref={}):
  found = []

  dirs    = ref.get('dirs',[])

  relpath = ref.get('relpath',0)
  ext     = ref.get('ext',[])

  inc     = ref.get('inc',qw('dir file'))
  if type(inc) is str:
    inc = inc.split(' ')

  for dir in dirs:
    d = Path(dir)
    for item in d.rglob('*'):
      full_path = str(item.as_posix())
      f = full_path
      if relpath:
        f = os.path.relpath(full_path,dir)

      ok = False
      for i in inc:
        ok = ok or (i == 'dir' and os.path.isdir(full_path))
        ok = ok or (i == 'file' and os.path.isfile(full_path))
        if ok:
          break

      if f and ok:
        found.append(f)

  return found

#https://stackoverflow.com/questions/33409207/how-to-return-value-from-exec-in-function
def convertExpr2Expression(Expr):
  Expr.lineno = 0
  Expr.col_offset = 0
  result = ast.Expression(Expr.value, lineno=0, col_offset = 0)

  return result

#https://stackoverflow.com/questions/33409207/how-to-return-value-from-exec-in-function
# exec with return
def x_bare(code,globs={},locs={}):
  try:
    code_ast = ast.parse(code)
  except SyntaxError as e:
    print(f'[ast.parse] SyntaxError: {e}')
    return

  #globs.update(globals())
  #locs.update(locals())
  #print(f'[util.x_bare], globs = {list(globs.keys())}')

  for var, val in globs.items():
    try:
      exec(f'global {var}; {var} = val')
    except:
      e = sys.exc_info()
      print(f'[Util.x_bare] global: {var}')

  init_ast = copy.deepcopy(code_ast)
  init_ast.body = code_ast.body[:-1]

  last_ast = copy.deepcopy(code_ast)
  last_ast.body = code_ast.body[-1:]

  try:
    #exec(compile(init_ast, "<ast>", "exec"), globs, locs)
    exec(compile(init_ast, "<ast>", "exec"), globs)
  except SyntaxError as e:
    print(f'SyntaxError: {e}')
    return

  result = None
  if type(last_ast.body[0]) == ast.Expr:
    try:
      result = eval(compile(convertExpr2Expression(last_ast.body[0]), "<ast>", "eval"))
    except SyntaxError as e:
      print(f'SyntaxError: {e}')
      return
  else:
    try:
      #exec(compile(last_ast, "<ast>", "exec"))
      exec(compile(last_ast, "<ast>", "exec"),globs)
    except SyntaxError as e:
      print(f'SyntaxError: {e}')
      return

  return result

def x(code,globs={},locs={}):
  result = None
  type = None

  try:
    result = x_bare(code,globs,locs)
  except TypeError as e:
    print(f'[util.x] TypeError: {e}')
  except NameError as e:
    print(f'[util.x] NameError: {e}')
  except:
    e = sys.exc_info()
    print(f'[Util.x_bare] {e[0]}')

  return result

def getx(obj, path = '', default = None, sep = '.', cp=False):
    keys = []
    if type(path) is str:
      keys = path.split(sep)
    elif type(path) is int:
      keys = [ f'{path}' ]
    elif type(path) is list:
      keys = path

    if not keys:
      if cp:
        default = copy.deepcopy(default)

      return default

    for k in keys:
      if obj in ['',None]:
        obj = default
        break
      if isinstance(obj,dict):
        if k in obj:
          obj = obj.get(k)
          if obj in [ None,'' ]:
            obj = default
        else:
          obj = default
          break
      elif isinstance(obj,object):
        if hasattr(obj,k):
          obj = getattr(obj, k)
          if obj in [ None,'' ]:
            obj = default
        else:
          obj = default
          break

    if cp:
      obj = copy.deepcopy(obj)

    return obj


def get(obj, path = '', default = None, sep = '.', cp=False):
    if type(path) is str:
      keys = path.split(sep)
    elif type(path) is list:
      keys = path

    if not keys:
      if cp:
        default = copy.deepcopy(default)

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

    if cp:
      obj = copy.deepcopy(obj)

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
    #lst = list(set(lst))
    unique = []

    for item in lst:
      if item in unique:
        continue
      else:
        unique.append(item)

    return unique

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)


# see also: readdict
def writedict(dat_file, dict={}):
  if not dat_file:
    return

  dkeys = list(dict.keys())
  dkeys.sort()
  lines = []
  for k in dkeys:
    v = dict.get(k)
    if v == None:
      v = ''
    lines.append(f'{k} {v}')

  txt = '\n'.join(lines) + '\n'
  with open(dat_file, 'w', encoding='utf8') as f:
    f.write(txt)

  return 1

# see also: writedict
def readdict(dat_file, opts={}):
    dict = {}
    if not (dat_file and os.path.isfile(dat_file)):
      return {}

    with open(dat_file,'r',encoding='utf8') as f:
      lines = f.readlines()
      while len(lines):
        line = lines.pop(0).strip()
        if re.match(r'^#',line) or (len(line) == 0):
          continue

        m = re.match(r'^\s*(\S+)\s+(.*)$',line)
        if m:
          key = m.group(1).strip()
          value = m.group(2).strip()
          dict.update({ key : value })

    return dict

def readarr(dat_file, opts={}):
    splitsep = opts.get('sep', re.compile(r'\s+'))

    vars = []
    if not (dat_file and os.path.isfile(dat_file)):
      return []

    with open(dat_file,'r',encoding='utf8') as f:
      lines = f.readlines()

    for line in lines:
      line = line.strip()
      if re.match(r'^#',line) or (len(line) == 0):
        continue

      if splitsep:
        F = re.split(splitsep, line)
        vars.extend(F)
      else:
        vars.append(line)

      vars = uniq(vars)

    return vars
