
import Base.Util as util
import Base.DBW as dbw
from Base.Core import CoreClass

import os,sys,re

class dbFile(CoreClass):
  images = None
  pages = None

class mxDB:

  # sqlite table columns, e.g. pages, imgs
  cols = {}

  # list of databases
  dbfile = dbFile()

  def init(self,args={}):
    self.img_root  = os.environ.get('IMG_ROOT')
    self.html_root = os.environ.get('HTML_ROOT')

    for k, v in args.items():
      setattr(self, k, v)

    for k in util.qw('img_root html_root'):
      self.dirs[k] = util.get(self,k) 

    if (not self.dbfile.images) and self.img_root:
      self.dbfile.images = os.path.join(self.img_root,'img.db')

    if (not self.dbfile.pages) and self.html_root:
      self.dbfile.pages = os.path.join(self.html_root,'h.db')

    self.cols['pages'] = dbw._cols({
      'db_file' : self.dbfile.pages,
      'table'   : 'pages',
    })

    return self

