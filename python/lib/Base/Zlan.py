
import os,sys
import re

from copy import copy
from copy import deepcopy

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)

plg = os.environ.get('PLG')
add_libs([ os.path.join(plg,'projs','python','lib') ])
import Base.DBW as dbw
import Base.Util as util
import Base.Const as const

def is_cmt(line):
  return re.match(r'^\s*#',line)

def lst_read(lines):
  lst = []

  line = lines[0]
  while 1:
    line = lines.pop(0)

    if is_cmt(line):
      continue

    mm = re.match(r'\t\t(\w+)',line)
    if not mm:
      lines.insert(0,line)
      break

    item = mm.group(1)
    item = item.strip()
    lst.append(item)

  return lst

def data(ref={}):
  zfile = util.get(ref,'file')

  if not (zfile and os.path.isfile(zfile)):
    return


  dat_file = os.path.join(plg,'projs','data','list','zlan_keys.i.dat')
  zkeys = util.readarr(dat_file)

  with open(zfile,'r') as f:
    lines = f.readlines()

  # loop variables
  flg = {
    'block'   : '',
    'save'   : '',
  }

  d_page = None
  d_global = {
    'listpush' : {},
    'dictex' : {},
    'setlist' : {},
    'setdict' : {},
    'set' : {},
  }
  off = None

  end = 0 
  eof = 0 

  shift = '\t'
###pats
  pats = { 
    'set'      : rf'^set\s+(\w+)(?:\s+(.*)|\s*)$',
    'setlist'  : rf'^setlist\s+(\w+)\s*$',
    'listpush' : rf'^listpush\s+(\w+)\s*$',
    'setdict'  : rf'^setdict\+(\w+)\s*$',
    'dictex'   : rf'^dictex\+(\w+)\s*$',
    'unset'    : rf'^unset\s+(\w+)\s*$',
  }
  pc = {}
  # compiled patterns
  for k in pats.keys():
    v = pats[k]
    pc[k] = re.compile(v)

  zdata = {}
  zorder = []

  while 1:
    #line = None

    if len(lines):
      line = lines.pop(0)
    else:
      eof = 1
      end = 1

    if end:
###save_page
      if flg.get('save') == 'page':
        if d_page:
          dd = deepcopy(d_page)

          if d_global:
            dg = deepcopy(d_global)
            for k, v in dg.items():
              if k in util.qw('set setlist setdict'):
                g_set = deepcopy(v)
                for kk in g_set.keys():
                  if not kk in dd:
                    dd[kk] = g_set.get(kk)

            for w in dg['listpush'].keys():
              l_push = dg['listpush'].get(w,[])
              w_lst = dd.get(w,[])
              w_lst.extend(l_push)
              dd[w] = w_lst

          url = dd.get('url')
          if url:
            zorder.append(url)
      
            u = util.url_parse(url)
      
            dd['host'] = u['host']
            zdata[url] = dd
  
      d_page = None
      end = 0

      if eof:
        break

    if len(lines) == 0:
      end = 1
      eof = 1
      if off:
        break
    else:
###get_line
      #line = lines.pop(0)
#      if is_cmt(line):
        #print(line)
        #if len(lines) == 0:
          #eof = 1
          #end = 1
        #continue

      m = re.match(r'^(\w+)', line)
      if m:
        end = 1
        word = m.group(1)
        prev = flg.get('block')

        if word == 'off':
          off = 1
        elif word == 'on':
          off = 0
        elif word == 'global':
          flg = { 'block' : 'global', 'save' : prev }

        elif word == 'page':
          flg = { 'block' : 'page', 'save' : prev }

      if off:
        continue

      #print(str(len(lines)) + ' ' + copy(line).strip('\n'))
  
###if_on
      m = re.match(r'^\t(.*)$',line)
      if m:
        line_t = m.group(1)
        end = 0

###f_block_global
        if flg.get('block') == 'global':

###m_global_unset
            m = re.match(pc['unset'], line_t)
            if m:
              k = m.group(1)
              if k in d_global:
                del d_global[k]

###m_global_set
            m = re.match(pc['set'], line_t)
            if m:
              k = m.group(1)
              v = m.group(2)
              if v:
                v = v.strip()
                d_global['set'].update({ k : v })

###m_global_list
            for j in util.qw('listpush setlist'):
              m = re.match(pc[j], line_t)
              if m:
                var = m.group(1)
                var_lst = lst_read(lines)
  
                if len(var_lst):
                  d_global[j].update({ var : var_lst })
    
###f_block_page
        if flg.get('block') == 'page':
            if not d_page:
              d_page = {}

###m_page_set
            m = re.match(pc['set'], line_t)
            if m:
              var = m.group(1)
              val = m.group(2)
              d_page.update({ var : val })

###m_page_setlist
            m = re.match(pc['setlist'], line_t)
            if m:
              var = m.group(1)
              var_lst = lst_read(lines)

              if len(var_lst):
                d_page.update({ var : var_lst })
    
  #print(d_global)
  zdata.update({ 'order' : zorder })

  return zdata
