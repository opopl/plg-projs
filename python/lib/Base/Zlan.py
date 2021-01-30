
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
  d_global = {}
  off = None

  end = 0 

  shift = '\t'
  # str patterns
  pats = { 
    'page_var_str'     : rf'^(?:(\w+))\s+(.*)$',
    'page_var_list'    : rf'^(\w+)\|list\|\s*$',
    'page_var_dict'    : rf'^(\w+)\|dict\|\s*$',
    'global_var_set'   : rf'^set\s+(?:(\w+))\s*=\s*(.*)$',
    'global_var_unset' : rf'^unset\s+(?:(\w+))\s*$',
  }
  pc = {}
  # compiled patterns
  for k in pats.keys():
    v = pats[k]
    pc[k] = re.compile(v)

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
        m = re.match(r'^\t(.*)$',line)
        if m:
          line_t = m.group(1)
          end = 0

          if flg.get('global'):
            m = re.match(pc['global_var_set'], line_t)
            if m:
              k = m.group(1)
              v = m.group(2)
              v = v.strip()
              d_global.update({ k : v })

            m = re.match(pc['global_var_unset'], line_t)
            if m:
              k = m.group(1)
              if k in d_global:
                del d_global[k]
    
###f_page
          if flg.get('page'):
            if not d_page:
              d_page = {}

            m = re.match(pc['page_var_str'], line_t)
            if m:
              var = m.group(1)
              val = m.group(2)
              d_page.update({ var : val })

            m = re.match(pc['page_var_list'], line_t)
            if m:
              var = m.group(1)
              var_lst = []
              while 1:
                line = lines.pop(0)
                mm = re.match(r'\t\t(\w+)',line)
                if not mm:
                  break
                item = mm.group(1)
                item = item.strip()
                var_lst.append(item)
    
          continue
    
    if end:
      if flg.get('page'):
        if d_page:
          dd = copy(d_page)
          if d_global:
            for k, v in d_global.items():
              dd[k] = v 
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
