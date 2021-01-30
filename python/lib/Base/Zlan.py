
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

  with open(zfile,'r') as f:
    lines = f.readlines()

  # loop variables
  flg = {
    'page'   : 0,
    'global' : 0,
  }

  d_page = None
  d_global = None
  off = None

  end = 0 

  shift = '\t'
  pat = rf'{shift}(?:(\w+))\s+(.*)$'
  pc = re.compile(pat)

  while 1:
    line = None
    if len(lines) == 0:
      end = 1
      if off:
        break
    else:
      line = lines.pop(0)

    if line:
      m = re.match(r'^(\w+)', line)
      if m:
        end = 1
        word = m.group(1)
        if word == 'off':
          off = 1
        elif word == 'on':
          off = 0
        elif word == 'global':
          flg = { 'global' : 1 }
        elif word == 'page':
          flg = { 'page'   : 1 }
  
      if not off:
        if re.match(r'^\t',line):
    
          end = 0
    
          m = re.match(pc, line)
          if m:
            k = m.group(1)
            v = m.group(2)
            if v:
              if flg.get('page'):
                if not d_page:
                  d_page = {}
                d_page.update({ k : v })
              if flg.get('global'):
                if not d_global:
                  d_global = {}
                d_global.update({ k : v })
    
          continue
    
    if end:
      if flg.get('page'):
        if d_page:
          dd = copy(d_page)
          url = dd.get('url')
          if url:
            zorder.append(url)
      
            u = util.url_parse(url)
      
            dd['host'] = u['host']
            zdata[url] = dd
  
      d_page = None
      end = 0

    if len(lines) == 0:
      break

  zdata.update({ 'order' : zorder })

  return zdata
