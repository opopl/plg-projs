
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

from Base.Core import CoreClass

class Zlan(CoreClass):

  lines = []
  line = None

  data = {}
  order = []

  off = None
  
  end = 0 
  eof = 0 
  
  shift = '\t'

  d_page = None
  d_global = None

  d_global = {
      'listpush' : {},
      'dictex' : {},
      'setlist' : {},
      'setdict' : {},
      'set' : {},
  }

  pats = { 
    'set'      : rf'^set\s+(\w+)(?:\s+(.*)|\s*)$',
    'setlist'  : rf'^setlist\s+(\w+)\s*$',
    'listpush' : rf'^listpush\s+(\w+)\s*$',
    'setdict'  : rf'^setdict\+(\w+)\s*$',
    'dictex'   : rf'^dictex\+(\w+)\s*$',
    'unset'    : rf'^unset\s+(\w+)\s*$',
  }


  flg = {
      'block'   : '',
      'save'   : '',
  }

  def _is_cmt(self):
    return re.match(r'^\s*#',self.line)

  def _lst_read(self):
    lst = []
  
    line = self.lines[0]
    while 1:
      self.line = self.lines.pop(0)
  
      if self._is_cmt(self.line):
        continue
  
      mm = re.match(r'\t\t(\w+)',self.line)
      if not mm:
        self.lines.insert(0,self.line)
        break
  
      item = mm.group(1)
      item = item.strip()
      lst.append(item)
  
    return lst

  def read_file(self,ref={}):
    file = self.file
    file = util.get(ref,'file',file)

    if not (file and os.path.isfile(file)):
      return
  
    dat_file = os.path.join(plg,'projs','data','list','zlan_keys.i.dat')
    self.keys = util.readarr(dat_file)
  
    with open(file,'r') as f:
      self.lines = f.readlines()

    return self

  def init_pc(self):
    self.pc = {}
    # compiled patterns
    for k in self.pats.keys():
      v = self.pats[k]
      self.pc[k] = re.compile(v)

    return self
  
  def get_data(self,ref={}):
    file = util.get(ref,'file')
    if file:
      self.file = file
    else:
      file = self.file
  
    # loop variables
    self                              \
        .read_file({ 'file' : file }) \
        .init_pc()                    \
        .loop()                    \
  
          
    #print(d_global)
    self.data.update({ 'order' : self.order })
  
    return self

  def b_page(self):

    if not self.d_page:
      self.d_page = {}
  
    m = re.match(self.pc['set'], self.line_t)
    if m:
      var = m.group(1)
      val = m.group(2)
      self.d_page.update({ var : val })
  
    m = re.match(self.pc['setlist'], self.line_t)
    if m:
      var = m.group(1)
      var_lst = self._lst_read()
  
      if len(var_lst):
        self.d_page.update({ var : var_lst })

    return self

  def b_global(self):

    m = re.match(self.pc['unset'], self.line_t)
    if m:
      k = m.group(1)
      if k in self.d_global:
        del d_global[k]
  
    m = re.match(self.pc['set'], self.line_t)
    if m:
      k = m.group(1)
      v = m.group(2)
      if v:
        v = v.strip()
        self.d_global['set'].update({ k : v })
  
    for j in util.qw('listpush setlist'):
      m = re.match(self.pc[j], self.line_t)
      if m:
        var = m.group(1)
        var_lst = self._lst_read()
  
        if len(var_lst):
          self.d_global[j].update({ var : var_lst })

    return self

  def process_line(self):

    m = re.match(r'^(\w+)', self.line)
    if m:
      self.end = 1
      word = m.group(1)
      prev = self.flg.get('block')
   
      if word == 'off':
        self.off = 1
      elif word == 'on':
        self.off = 0
      elif word == 'global':
        self.flg = { 'block' : 'global', 'save' : prev }
   
      elif word == 'page':
        self.flg = { 'block' : 'page', 'save' : prev }
   
        return self
   
    m = re.match(r'^\t(.*)$',self.line)
    if m:
      self.line_t = m.group(1)
      self.end = 0
   
      if self.flg.get('block') == 'global':
        self.b_global()
      
      if self.flg.get('block') == 'page':
        self.b_page()

    return self

  def process_end(self):
    ###save_page
    if self.flg.get('save') == 'page':
      if self.d_page:
        dd = deepcopy(self.d_page)
    
        if self.d_global:
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
          self.order.append(url)
    
          u = util.url_parse(url)
    
          dd['host'] = u['host']
          self.data[url] = dd
    
    self.d_page = None
    self.end = 0

    return self

  def loop(self):
  
    while 1:
        if len(self.lines):
          self.line = self.lines.pop(0)
    
        if self.d_page:
            print(self.d_page)
  
        if self.line:
          print(f'end => {self.end}, line => {self.line}')
    
        if self.end:
          self.process_end()  

          if self.eof:
            break
    
        if len(self.lines) == 0:
          self.end = 1
          self.eof = 1
          if self.off:
            break
        else:
          if self._is_cmt():
            continue

          self.process_line()

    return self

