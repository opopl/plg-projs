
import os,sys
import json
import copy

import Base.Util as util

from dict_recursive_update import recursive_update

class CoreClass:

  def __init__(self,args={}):
    recursive_update(self.__dict__, args)
    #for k, v in args.items():
      #setattr(self, k, v)

  def _json(self):
    jsd = json.dumps(self.__dict__)
    return jsd

  def dict(self,ref={}):
    data = {}

    exclude = ref.get('exclude',[])
    exclude.extend(util.qw('__dict__ __module__'))

    include = ref.get('include',[ '@all' ])
    inew = []
    for i in include:
      if i == '@all':
        inew.extend(include)
      else:
        inew.append(i)

    include = inew

    for k in dir(self):
      ok = 1
      ok = ok and k not in exclude
      ok = ok and k in include

      if not ok:
        continue

      v = getattr(self,k)
      if type(v) in [ dict,list,str,int ]:
        data.update({ k : v })

    return data

  def listadd(self, path = None, items = []):
    lst = util.get(self,path,[])

    if type(items) is str:
      items = util.qw(items)

    lst.extend(items)

    setattr(self, path, lst)

    return self

  def set(self, ref = {}):
    for k, v in ref.items():
      setattr(self, k, v)

  def get(self, path='', default=None, cp=False):
    val = self.__dict__
    if cp:
      val = copy.deepcopy(val)

    if path:
      val = util.get(self,path=path,default=default,cp=cp)

    return val

  def len(self):
    return len(self.__dict__)
