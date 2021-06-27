

from pathlib import Path
import Base.Util as util

import os,re,sys

class mixFileSys:
  def _dir(self, arg = {}, *args):
    '''
       self._dir({ obj = 'out.tmpl', fs = '' })
       self._dir('out.tmpl')
       self._dir('img_root','tmp')
    '''

    dir      = None
    path_fs  = []
    path_obj = []

    if type(arg) is dict:
      path_obj = util.get(arg,'obj',[])
      path_fs  = util.get(arg,'fs',[])

    elif type(arg) is str:
      path_obj = arg
      if args:
        if type(args[0]) is str:
          path_fs = args[0].split(' ')
        elif type(args[0]) is list:
          path_fs = args[0]

    if path_obj:
      if type(path_obj) is str:
        z = path_obj.split(' ')
        dir = util.get(self.dirs,z.pop(0))
        if len(z):
          path_fs = z + path_fs

      elif type(path_obj) is list:
        dir = util.get(self.dirs,path_obj)

    if dir:
      a = [ dir ]
      if path_fs:
        a.extend(path_fs)
        dir = str(Path(*a))

    
    return dir

  def _file_mtime(self, id):
    f = self._file(id)

    if not self._file_exist(id):
      return 0 

    mt = os.stat(f).st_mtime
    mt = int(mt)
    return mt

  def _file_exist(self, id):
    f = self._file(id)

    ok = True if (f and os.path.isfile(f)) else False
    return ok

  def _file(self, id):

    f = util.get(self,[ 'files' , id ])
    return f

# True if left.mtime > right.mtime, i.e. 'left' is more recent that 'right'
  def _file_mtime_gt(self, left, right):
    return ( self._file_mtime(left) > self._file_mtime(right) )

