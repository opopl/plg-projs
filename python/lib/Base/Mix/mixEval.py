
import logging
import os
import re

import Base.Util as util

from copy import copy
from copy import deepcopy

from dict_recursive_update import recursive_update

class mixEval:
  eval_ids = ['app']

  def evl(self,path=''):
    slf = self.get(cp=True)
    slf = self._eval_all(slf)

    recursive_update(self.__dict__,slf)

    return self

  def _eval_str(self,str='',id = 'app'):
    opn = '{'
    cls = '}'
    regex = rf'@{id}\{opn}([^{opn}{cls}]*)\{cls}'

    chars = [c for c in str]

    if id == 'app':
      obj = self
    elif id == 'suite':
      obj = self._suite()
    elif id == 'step':
      obj = self.vars_step

    i = 0
    while 1:
      i += 1 
      m = re.search(regex,str)
      if not m:
        break

      start = m.span(0)[0]
      end   = m.span()[1]
  
      key = m.group(1)
      val = util.get(obj, path=key, default='', sep='/' ) or ''

      str_new = str[0:start] + f'{val}' + str[end:]
      str = str_new

    return str

  def _eval_list_all(self,list=[]):
    w = deepcopy(list)
    new = []
    for k in w:
      val = self._eval_all(k)
      new.append(val)

    return new

  def _eval_list(self,list=[],id = 'app'):
    w = deepcopy(list)
    new = []
    for k in w:
      val = self._eval(k,id=id)
      new.append(val)

    return new

  def _eval_str_all(self,str=''):
    ids = self.eval_ids

    while 1:
      str_ = str
      for i in ids:
        str_ = self._eval_str(str_,id=i)

      if str_ == str:
        break
      str = str_
      
    return str_

  def _eval( self, var='', id='', ids=[] ):
    if not len(ids):
      if not id:
        ids = self.eval_ids
      else:
        ids = [ id ]

    w = copy(var)
    for i in ids:
      if type(w) in [dict]:
        w = self._eval_dict(dict=w,id=i)
      elif type(w) in [list]:
        w = self._eval_list(list=w,id=i)
      elif type(w) in [str]:
        w = self._eval_str(str=w,id=i)

    return w

  def _eval_all( self, var='' ):
    w = copy(var)
    if type(w) in [dict]:
      w = self._eval_dict_all(dict=w)
    elif type(w) in [list]:
      w = self._eval_list_all(list=w)
    elif type(w) in [str]:
      w = self._eval_str_all(str=w)
    return w

  def _eval_dict_all(self,dict={}):
    w = deepcopy(dict)
    for k, v in w.items():
      val = self._eval_all(v)
      w.update({ k : val })

    return w

  def _eval_dict(self,dict={},id = 'app'):
    w = deepcopy(dict)
    for k, v in w.items():
      val = self._eval(v,id=id)
      w.update({ k : val })
    return w


