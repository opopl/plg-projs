
import os,sys
import re

from copy import copy
from copy import deepcopy

import Base.DBW as dbw
import Base.Util as util
import Base.Const as const

from Base.Core import CoreClass

class Zlan(CoreClass):

  def __init__(self,args={}):
    super().__init__(args)

    lines = []
    line = None

    self.data = {
      'order'      : [],
      'lines_main' : [],
      'lines_eof'  : [],
    }
  
    self.order = {
      'all' : [],
      'on' : [],
    }

    self.off = None
    
    self.end = 0 
    self.eof = 0 
    
    self.shift = '\t'
  
    self.d_page = None
    self.d_global = None
  
    self.d_global = {
        'listpush' : {},
        'dictex' : {},
        'setlist' : {},
        'setdict' : {},
        'set' : {},
    }
  
    self.pats = { 
      'set'      : rf'^set\s+(\w+)(?:\s+(.*)|\s*)$',
      'setlist'  : rf'^setlist\s+(\w+)\s*$',
      'listpush' : rf'^listpush\s+(\w+)\s*$',
      'setdict'  : rf'^setdict\+(\w+)\s*$',
      'dictex'   : rf'^dictex\+(\w+)\s*$',
      'unset'    : rf'^unset\s+(\w+)\s*$',
    }

    self.flg = {
        'block'   : '',
        'save'   : '',
    }


  def _is_eof(self):
    return re.match(r'^eof\s*$',self.line)

  def _is_cmt(self):
    return re.match(r'^\s*#',self.line)

  def _lst_read(self):
    lst = []
  
    line = self.lines[0]
    while 1:
      if len(self.lines) == 0:
        break

      self.line = self.lines.pop(0)
  
      if self._is_cmt():
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
  
    plg = os.environ.get('PLG','')
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

  def save(self,ref={}):
    zdata = util.get(ref,'zdata',self.data)
    d_i   = util.get(ref,'d_i')
    zfile = util.get(ref,'file')

    for j in util.qw('lines_main lines_eof'):
      if not j in zdata:
        zdata[j] = []

    if d_i == None:
      return self
    if not type(d_i) is dict:
      return self

    zdata['lines_main'].append('page')

    keys = [ 'url' ]
    for k in d_i.keys():
      if k == 'url':
        continue
      keys.append(k)

    if not 'url' in keys:
      return self

    for k in keys:
      v = d_i.get('k')
      if v == None:
        continue

      zdata['lines_main'].append(f'\tset {k} {v}')

    zlines = []
    zlines.extend(zdata['lines_main'])
    zlines.extend(zdata['lines_eof'])

    with open(zfile, 'w') as f:
      f.write(zlines)

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
        .loop()                       \
          
    #print(d_global)
    self.data.update({ 
      'order' : self.order 
    })
  
    return self

  def b_page(self):

    if not self.d_page:
      self.d_page = {}
      if self.off:
       self.d_page['off'] = 1
  
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
        del self.d_global[k]
  
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

  def line_match_block_word(self):
    m = re.match(r'^(\w+)', self.line)
    if not m:
      return self

    self.end = 1
    word = m.group(1)
    prev = self.flg.get('block')
 
    if word == 'off':
      self.off = 1

    if word == 'eof':
      self.eof = 1

    elif word == 'on':
      self.off = 0

    elif word == 'global':
      self.flg = { 'block' : 'global', 'save' : prev }
 
    elif word == 'page':
      self.flg = { 'block' : 'page', 'save' : prev }
 
    return self

  def line_match_block_inner(self):
    m = re.match(r'^\t(.*)$',self.line)
    if not m:
      return self

    #print('[line_match_block_inner]')

    self.line_t = m.group(1)
    self.end = 0
 
    if self.flg.get('block') == 'global':
      self.b_global()
    
    if self.flg.get('block') == 'page':
      self.b_page()

    return self
  
  def process_end(self):
    #print(f'[process_end]')
    #print(self.d_page)

    ###save_page
    if self.flg.get('save') == 'page':
      if self.d_page:
        dd = deepcopy(self.d_page)
    
        if self.d_global:
          dg = deepcopy(self.d_global)
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
          if not dd.get('off'):
            self.order['on'].append(url)
          self.order['all'].append(url)
    
          u = util.url_parse(url)
    
          dd['host'] = u['host']
          self.data[url] = dd
    
    self.d_page = None
    self.end = 0

    return self

  def pl(self):
    l = self.line
    print(f'line => {l}')
    print(f'is_end => {self.end}')
    return self

  def add_eof(self):
    self.data['lines_eof'].append(self.line)

    return self

  def add_main(self):
    self.data['lines_main'].append(self.line)

    return self

  def loop(self):
  
    while 1:
        if len(self.lines):
          self.line = self.lines.pop(0)

          if self.eof:
            self.add_eof()
            continue

          self.line_match_block_word()

          if self.eof:
            self.add_eof()
            continue

          self.add_main()

          self.line_match_block_inner()

          #print(f'd_page => {self.d_page}')
          #print(f'flg => {self.flg}')
          #print(f'off => {self.off}')

          if self.end:
            self.process_end()  
            self.end = 0

          continue

        self.process_end()  

        break

    return self
