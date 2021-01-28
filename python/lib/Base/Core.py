import os,sys

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)

plg = os.environ.get('PLG')
add_libs([ os.path.join(plg,'projs','python','lib') ])
import Base.Util as util

class CoreClass:

  def __init__(self,args={}):
    for k, v in args.items():
      setattr(self, k, v)

  def set(self, ref = {}):
    for k, v in ref.items():
      setattr(self, k, v)

  def get(self, path, default=None):
    val = util.get(self,path,default)
  
    return val

  def len(self):
    return len(self.__dict__)
