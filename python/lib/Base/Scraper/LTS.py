
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
