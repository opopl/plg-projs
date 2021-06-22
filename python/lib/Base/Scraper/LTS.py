
import os

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

from Base.Mix.mixCmdRunner import mixCmdRunner
from Base.Mix.mixLogger import mixLogger
from Base.Mix.mixGetOpt import mixGetOpt

from Base.Zlan import Zlan
from Base.Core import CoreClass

class LTS(CoreClass,mixLogger,mixCmdRunner,mixGetOpt):
  usage='''
  PURPOSE
        This script is for handling LTS
  '''

  skip_get_opt = False

  def __init__(self,args={}):
    self.lts_root  = os.environ.get('P_SR')

    for k, v in args.items():
      setattr(self, k, v)

  def main(self):
    acts = [
      'get_opt',
      ''
    ]

    util.call(self,acts)

    return self

  def get_opt_apply(self):
    if not self.oa:
      return self

#    for k in util.qw('f_yaml f_zlan f_input_html'):
      #v  = util.get(self,[ 'oa', k ])
      #m = re.match(r'^f_(\w+)$', k)
      #if m:
        #ftype = m.group(1)
        #self.files.update({ ftype : v })

    return self

  def get_opt(self):
    if self.skip_get_opt:
      return self

    mixGetOpt.get_opt(self)

    self.get_opt_apply()

    return self
