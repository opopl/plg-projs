
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

from plg.projs.Prj.Section import Section
from plg.projs.Prj.ListSections import ListSections

from Base.Zlan import Zlan
from Base.Core import CoreClass

class Prj(
     CoreClass,
     mixFileSys,
  ):

  b2i = {
    'projs' : {
       'tags' : 'tag' 
    }
  }

  def __init__(self,args={}):

    CoreClass.__init__(self,args)
    self.init_db()

  # add section to database
  def add(self,section={}):
    d = {}; dd = {}

    cols = Section.cols

    tbase = 'projs'

    if type(section) in [dict]:
      dd = section
    elif type(section).__name__ == 'Section':
      dd = section.__dict__
    else:
      return self

    for k, v in dd.items():
      if k in cols:
        d.update({ k : v })

    ok = True
    for k in ['sec','file','proj']:
      v = d.get(k)
      ok = ok and v not in [ None, '' ] 
      if not ok:
        break

    if not ok:
      return self

    dbw.insert_update_dict({
      'db_file' : self.db_file,
      'table'   : tbase,
      'insert'  : d,
      'on_list' : ['file'],
    })

    b2i = self.b2i.get(tbase,{})

    jcol = 'file'
    jval = d.get(jcol)

    for bcol in ['tags','author_id']:
      bval = d.get(k) or ''

      if bval:
        ivals = string.split_n_trim(bval,sep=',')

        icol = b2i.get(bcol,bcol)

        itb = f'_info_{tbase}_{bcol}' 

        for ival in ivals:
          dbw.insert_dict({
            'db_file' : self.db_file,
            'table'   : itb,
            'insert'  : { jcol : jval, icol : ival   },
          })

    return self

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
    where = ref.get('where',{})

    tbase = 'projs'
    r = {
       'db_file' : self.db_file,
       'tbase'  : tbase,
       'jcol'   : 'file',
       'bcols'  : [ 'tags','author_id' ],
       'b2i'    : self.b2i.get(tbase,{})
       'bwhere' : where,
    }
    dbw.base2info(r)

    return self

  def _listsecs(self, ref = {}):
    pat  = ref.get('pat','')
    ext  = ref.get('ext','')

    proj = ref.get('proj',self.proj)

    regexp = {}
    if pat:
      regexp.update({ 'sec' : pat })
    if ext:
      regexp.update({ 'file' : f'\.{ext}$' })

    r = dbw.select({ 
      'table'   : 'projs',
      'db_file' : self.db_file,
      'orderby' : { 'sec' : 'asc' },
      'select' : [ 'sec', f'RGX("{pat}",sec)' ],
      'where' : {
        'proj'    : proj,
        '@regexp' : regexp
      }
    })
    rows = r.get('rows',[])

    listsecs = ListSections({ 'rows' : rows })

    return listsecs
