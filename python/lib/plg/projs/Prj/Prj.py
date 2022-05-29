
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

  root = None
  rootid = None

  proj = None
  sec = None

  def __init__(self,args={}):

    CoreClass.__init__(self,args)
    self.init_db()

  def sec_children_delete(self, ref={}):
    sec      = ref.get('sec','')
    proj     = ref.get('proj',self.proj)

    children = self._sec_children_db({
       'proj' : proj,
       'sec'  : sec,
    })

    for child in children:
       self.sec_delete({
         'proj' : proj,
         'sec'  : child,
       })

    return self

  def sec_delete(self,ref={}):
    proj = ref.get('proj',self.proj)

    where  = { 'proj' : proj }

    fields = [ 'sec', 'url' ]
    for k in fields:
      if k in ref:
        v = ref.get(k)
        where.update({ k : v })

    sec = where.get('sec','')
    url = where.get('url','')
    if url:
      q = 'SELECT sec FROM projs WHERE url = ?'
      sec =  dbw.sql_fetchval(q, [url], { 'db_file' : db_file })

    sd = self._sec_data({ 
      'proj' : proj, 
      'sec'  : sec 
    })
    file_ex = sd.get('@file_ex')
    file_path = sd.get('@file_path')

    ok = sd and file_ex and file_path
    if not ok:
      return self

    dbw.delete({
      'where'   : { 'sec' : sec, 'proj' : proj },
      'db_file' : self.db_file,
      'table'   : 'projs'
    })

    if util.git_has(file_path):
      util.git_rm(file_path)

    elif os.path.isfile(file_path):
      os.remove(file_path)

    return self

  def db_sec_insert_children(self,ref={}):
    sec      = ref.get('sec','')
    proj     = ref.get('proj',self.proj)
    children = ref.get('children',[])

    ok = 1 and sec and proj and len(children)
    if not ok:
      return self

    sd = self._sec_data({
        'sec'  : sec,
        'proj' : proj,
    });

    ok = ok and sd and sd.get('@file_ex')
    if not ok:
      return self

    file = sd.get('file')

    for child in children:
        sdc = self._sec_data({
          'sec'  : child,
          'proj' : proj,
        })

        if not (sdc and sdc.get('@file_ex')):
           continue

        file_child = sdc.get('file')

        ins_child = {
           'file_parent' : file,
           'file_child'  : file_child,
        }

        dbw.insert_update_dict({
           'db_file' : self.db_file,
           'table'   : 'tree_children',
           'insert'  : ins_child,
           'uniq'    : 1,
        })

    return self

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

    sec  = d.get('sec')
    file = d.get('file')
    proj = d.get('proj')

    dbw.insert_update_dict({
      'db_file' : self.db_file,
      'table'   : tbase,
      'insert'  : d,
      'on_list' : ['file'],
    })

    parent_sec = d.get('parent','')
    if parent_sec:
      self.db_sec_insert_children({
         'proj'     : proj,
         'sec'      : parent_sec,
         'children' : [ sec ]
      })

    b2i = self.b2i.get(tbase,{})

    jcol = 'file'
    jval = d.get(jcol)

    for bcol in ['tags', 'author_id']:
      bval = d.get(bcol) or ''

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

  # get children from database
  def _sec_children_db(self, ref={}):
    proj = ref.get('proj',self.proj)
    sec  = ref.get('sec',self.sec)

    p = [ sec ]
    q = f'''SELECT
                projs.sec
            FROM
                projs
            INNER JOIN tree_children
            ON
                projs.file = tree_children.file_child
            WHERE
                tree_children.file_parent IN
                ( SELECT file FROM projs WHERE sec = ? )
         '''

    children = dbw.sql_fetchlist(q,p,{
      'db_file' : self.db_file,
    })

    return children

# same as in Prj.pm
#   retrieve database data for section
  def _sec_data(self, ref={}):
    proj = ref.get('proj',self.proj)
    sec  = ref.get('sec',self.sec)

    rw = dbw.select({
      'db_file' : self.db_file,
      'table' : 'projs',
      'where' : {
        'sec'  : sec,
        'proj' : proj,
      },
      'output' : 'first_row'
    })

    if not rw:
      return

    file      = rw.get('file')
    file_path = self._sec_file_path({ 'file' : file })
    file_ex   = os.path.isfile(file_path)

    rw.update({
      '@file_path' : file_path,
      '@file_ex'   : file_ex,
    })

    return rw

# same as in Prj.pm
  def _sec_file_path(self, ref={}):
    root = ref.get('root',self.root)
    file = ref.get('file','')

    if not (file and root):
      return ''

    file_path = os.path.join(root, file)

    return file_path

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
       'b2i'    : self.b2i.get(tbase,{}),
       'bwhere' : where,
    }
    dbw.base2info(r)

    return self

  # return
  def _section(self, ref = {}):
    proj = ref.get('proj',self.proj)

    w = {}
    for k in ['sec','file','url']:
      v = ref.get(k)
      if v not in ['',None]:
        w.update({ k : v })

    listsecs = self._listsecs({ 'proj' : proj, 'where' : w })

    section = listsecs.first

    return section

  def _list(self, bcol='', ref = {}):
    where = {}

    tbase = 'projs'
    lst = []

    if bcol in ['tags','author_id']:
      itb = f'_info_{tbase}_{bcol}'
      icol = self.b2i.get(tbase,{}).get(bcol,bcol)

      if icol:
        q = f'''SELECT DISTINCT {icol} FROM {itb} ORDER BY {icol} ASC'''
        p = []

        lst = dbw.sql_fetchlist(q,p, { 'db_file' : self.db_file })

    return lst

  def _listsecs(self, ref = {}):
    pat  = ref.get('pat','')
    ext  = ref.get('ext','')

    iwhere = ref.get('where',{})

    proj = ref.get('proj',self.proj)

    regexp = {}
    if pat:
      regexp.update({ 'sec' : pat })
    if ext:
      regexp.update({ 'file' : f'\.{ext}$' })

    where = { 'proj' : proj }
    if len(regexp):
      where.update({ '@regexp' : regexp })
    where.update(iwhere)

    r = dbw.select({
      'table'   : 'projs',
      'db_file' : self.db_file,
      'orderby' : { 'sec' : 'asc' },
      'where'   : where,
    })
    rows = r.get('rows',[])

    listsecs = ListSections({ 'rows' : rows })

    return listsecs
