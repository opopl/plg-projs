
import os,sys
import re

from copy import copy
from copy import deepcopy

import Base.DBW as dbw
import Base.Util as util
import Base.Const as const

from Base.Core import CoreClass

class Zlan(CoreClass):

  file = None

  # regexp definitions, to be compiled into self.pc
  pats = {}

  # compiled regular expressions, obtained
  #   from self.pats
  pc  = {}

  data  = {}
  order = {}

  off = None
  end = 0
  eof = 0

  var_types = {
    'int' : util.qw('limit redo'),
  }

  d_page   = None
  d_global = None

  def __init__(self,args={}):
    super().__init__(args)

    self.reset()
  
    self.pats = { 
      'set'      : rf'^set\s+(\w+)(?:\s+(.*)|\s*)$',
      'setlist'  : rf'^setlist\s+(\w+)\s*$',
      'listpush' : rf'^listpush\s+(\w+)\s*$',
      'setdict'  : rf'^setdict\+(\w+)\s*$',
      'dictex'   : rf'^dictex\+(\w+)\s*$',
      'unset'    : rf'^unset\s+(\w+)\s*$',
    }


  def _is_eof(self):
    return re.match(r'^eof\s*$',self.line)

  def _is_cmt(self):
    return re.match(r'^\s*#',self.line)

  def reset(self):

    lines = []
    line  = None

    self.data = {
      'order'      : [],
      'lines_main' : [],
      'lines_eof'  : [],
    }

    self.order = {
      'all' : [],
      'on'  : [],
    }

    self.off = None
    
    self.end = 0 
    self.eof = 0 
    
    self.shift = '\t'
  
    self.d_page = None
  
    self.d_global = {
        'listpush' : {},
        'dictex'   : {},
        'setlist'  : {},
        'setdict'  : {},
        'set'      : {},
    }

    self.flg = {
        'block'   : '',
        'save'    : '',
    }

    return self

  def _lst_read(self):
    lst = []
  
    line = self.lines[0]
    while 1:
      if len(self.lines) == 0:
        break

      self.line = self.lines.pop(0).strip("\n")
      self.line_add_main()
  
      if self._is_cmt():
        continue
  
      mm = re.match(r'\t\t(\w+)',self.line)
      if not mm:
        self.lines.insert(0,self.line)
        self.data['lines_main'].pop()
        break
  
      item = mm.group(1)
      item = item.strip()
      lst.append(item)
  
    return lst

  def read_file(self,ref={}):
    file = self.file
    file = util.get(ref,'file',file)

    if not (file and os.path.isfile(file)):
      return self
  
    plg       = os.environ.get('PLG','')
    dat_file  = os.path.join(plg,'projs','data','list','zlan_keys.i.dat')
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

  def insert(self,ref={}):
    d_i      = util.get(ref,'d_i',{})

    d_i_list = util.get(ref,'d_i_list',[])
    if len(d_i):
      d_i_list.append(d_i)

    for itm in d_i_list:
      if not (itm and type(itm) is dict and len(itm)):
        continue

      url = util.get(itm,'url')
      if not url:
        continue

      if url in self.data.keys():
        continue

      self.data[url] = itm
  
      lines_page = []
      lines_page.append('page')
  
      keys_o = util.qw('url tag')
      keys = []
      keys.extend(keys_o)

      for k in itm.keys():
        if k in keys_o:
          continue
        keys.append(k)
  
      for k in keys:
        v = itm.get(k)
        if v == None or v == '':
          continue
  
        lines_page.append(f'\tset {k} {v}')
      
      if len(lines_page):
        self.data['lines_main'].extend(lines_page)

    return self

  def save2fs(self,ref={}):
    file_in   = util.get(ref,'file_in',self.file)
    file_out  = util.get(ref,'file_out',self.file)

    data_in  = util.get(ref,'data',[])
    if len(data_in):
      self.data = data_in

    d_i_list = util.get(ref,'d_i_list',[])

    if not len(d_i_list):
      return self

    self                        \
        .get_data({             \
          'file' : file_in      \
        })                      \
        .insert({               \
          'd_i_list' : d_i_list \
        })                      \
        .w_file({               \
          'file' : file_out     \
        })                      \

    return self

  def w_file(self,ref={}):
    file_out = util.get(ref,'file',self.file)

    for j in util.qw('lines_main lines_eof'):
      if not j in self.data:
        self.data[j] = []

    zlines = []
    zlines.extend(self.data['lines_main'])
    zlines.extend(self.data['lines_eof'])

    ztext = "\n".join(zlines) + "\n"
    with open(file_out, 'w') as f:
      f.write(ztext)

    return self
  
  def get_data(self,ref={}):
    file = util.get(ref,'file','')
    if file:
      self.file = file
    else:
      file = self.file

    if not file:
      return self

    self.reset()
  
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

  def _has_url(self, url):
    return ok

  def _value_process(self, var, value):
    pt = [
      '^"(.*)"$',
      '^(.*)$',
    ]

    while 1:
      if var in self.var_types['int']:
        m = re.match(r'^(\d+)$', value)
        if m:
          value = int(m.group(1))
          break

      for p in pt:
        m = re.match(rf'{p}', value)
        if m:
          value = m.group(1)

      break

    return value

  def b_page(self):

    if not self.d_page:
      self.d_page = {}
      if self.off:
        self.d_page['off'] = 1
  
    m = re.match(self.pc['set'], self.line_t)
    if m:
      var   = m.group(1)
      value = m.group(2)
      value = self._value_process(var, value)
      self.d_page.update({ var : value })
  
    m = re.match(self.pc['setlist'], self.line_t)
    if m:
      var = m.group(1)
      var_lst_read = self._lst_read()
  
      if len(var_lst_read):
        #self.d_page.update({ var : var_lst_read })
        var_lst = util.get( self.d_page, [ var ], [] )
        var_lst.extend(var_lst_read)

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
      var = m.group(1)
      value = m.group(2)
      if value:
        value = self._value_process(var, value)
        self.d_global['set'].update({ var : value })
  
    for j in util.qw('listpush setlist'):
      m = re.match(self.pc[j], self.line_t)
      if m:
        var = m.group(1)
        var_lst_read = self._lst_read()
  
        if len(var_lst_read):
          var_lst = util.get( self.d_global, [ j, var ], [] )
          var_lst.extend(var_lst_read)

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

    self.flg = { 
       'block' : word,
       'save'  : prev
    }

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

  def line_add_eof(self):
    self.data['lines_eof'].append(self.line)

    return self

  def line_add_main(self):
    self.data['lines_main'].append(self.line)

    return self

  def loop(self):
  
    while 1:
        if len(self.lines):
          self.line = self.lines.pop(0).strip("\n")

          if self.eof:
            self.line_add_eof()
            continue

          self.line_match_block_word()

          if self.eof:
            self.line_add_eof()
            continue

          self.line_add_main()

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
