
import os,re,sys

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Rgx as rgx
import plg.projs.db as projs_db

from pathlib import Path

import jinja2

from Base.Mix.mixCmdRunner import mixCmdRunner
from Base.Mix.mixLogger import mixLogger
from Base.Mix.mixLoader import mixLoader
from Base.Mix.mixGetOpt import mixGetOpt
from Base.Mix.mixFileSys import mixFileSys

from Base.Zlan import Zlan
from Base.Core import CoreClass

class Prj(
     CoreClass,
     mixFileSys,
  ):

  def __init__(self,args={}):

    CoreClass.__init__(self,args)

  def _sections(self, ref = {}):
    pat  = ref.get('pat','')
    ext  = ref.get('ext','')

    proj = ref.get('proj',self.proj)

    regexp = {}
    if pat:
      regexp.update({ 'sec' : pat })
    if ext:
      regexp.update({ 'file' : f'\.{ext}$' })

    secs = dbw.select({ 
      'table'   : 'projs',
      'db_file' : self.db_file,
      'select' : 'sec',
      'output' : 'list',
      'orderby' : { 'sec' : 'asc' },
      'where' : {
        'proj' : proj,
        '@regexp' : regexp
      }
    })

    return secs
