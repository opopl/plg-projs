
import os

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

from Base.Zlan import Zlan
from Base.Core import CoreClass

#class LTS(CoreClass,mixLogger,mixCmdRunner):
class LTS(CoreClass):
  def __init__(self,args={}):
    self.lts_root  = os.environ.get('P_SR')

    for k, v in args.items():
      setattr(self, k, v)

  def main(self):
    return self
