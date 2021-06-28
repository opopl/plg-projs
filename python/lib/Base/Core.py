
import os,sys
import json

import Base.Util as util

class CoreClass:

  def __init__(self,args={}):
    for k, v in args.items():
      setattr(self, k, v)

  def _json(self):
    jsd = json.dumps(self.__dict__)
    return jsd

  def dict(self,ref={}):
    data = {}

    exclude = ref.get('exclude',[])
    exclude.extend(util.qw('__dict__ __module__'))

    for k in dir(self):
      if k in exclude:
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

  def get(self, path, default=None):
    val = util.get(self,path,default)
  
    return val

  def len(self):
    return len(self.__dict__)
