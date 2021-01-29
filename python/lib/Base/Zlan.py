
import os,sys
import re

from copy import copy

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)

plg = os.environ.get('PLG')
add_libs([ os.path.join(plg,'projs','python','lib') ])
import Base.DBW as dbw
import Base.Util as util
import Base.Const as const

def data(ref={}):
  zfile = util.get(ref,'file')

  if not (zfile and os.path.isfile(zfile)):
    return

  zdata = {}
  zorder = []

  dat_file = os.path.join(plg,'projs','data','list','zlan_keys.i.dat')
  zkeys = util.readarr(dat_file)

  flags = {}
  d = {}

  with open(zfile,'r') as f:
    lines = f.readlines()

  save = 0
  while len(lines):
    line = lines.pop(0)
    save = 0

    if (len(lines) == 0) or (re.match(r'^page', line)):
      save = 1

    if re.match(r'^\t',line):
      for k in zkeys:
        pat = rf'\t{k}\s+(.*)$'
        p = re.compile(pat)
        m = re.match(pat, line)
        if m:
          v = m.group(1)
          if v:
            d.update({ k : v })

    if save:
      url = copy(d).get('url')
      if url:
        dd = copy(d)

        zorder.append(url)
  
        u = util.url_parse(url)
  
        dd['host'] = u['host']
        zdata[url] = dd
  
      d = {}

  zdata.update({ 'order' : zorder })

  return zdata
