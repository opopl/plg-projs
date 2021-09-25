
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
    self.init_db()

  def init_db(self):
    plg = os.environ.get('PLG')
    sql_dir = os.path.join(plg,'projs','data','sql')

    ff = Path(sql_dir).glob('create_table_*.sql')
    for f in ff:
      sql_file = f.as_posix()
      dbw.sql_do({ 
        'sql_file' : sql_file,
        'db_file'  : self.db_file
      })


    return self

  def _tag(self, ref = {}):
    return ''

# fill table fileinfo
  def db_base2info(self, ref = {}):
    proj = ref.get('proj',self.proj)

    r = {
       'db_file' : self.db_file,
       'tbase'  : 'projs',
       'jcol'   : 'file',
       'bcols'  : [ 'tags','author_id' ],
       'b2i'    : { 'tags' : 'tag' },
       'bwhere' : { 'proj' : proj },
    }
    dbw.base2info(r)

    return self

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
