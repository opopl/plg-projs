
# ----------------------------
import os,sys

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)

plg = os.environ.get('PLG')
add_libs([ os.path.join(plg,'projs','python','lib') ])
import Base.DBW as dbw
import Base.Util as util
import Base.Const as const
# ----------------------------

class SitePage:

  soup        = None
  app         = None
  date_format = ''

  def __init__(self,args={}):
    for k, v in args.items():
      setattr(self, k, v)

  def get_author(self,ref={}):
    return self

  def get_date(self,ref={}):
    return self
