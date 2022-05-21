
import os,re,sys

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Rgx as rgx

from pathlib import Path

import jinja2

from Base.Core import CoreClass

class Section(
     CoreClass
  ):

  sec  = None
  proj = None

  cols = [
    'author_id',
    'date',
    'fid',
    'file',
    'id',
    'parent',
    'pic',
    'pid',
    'proj',
    'projtype',
    'rootid',
    'sec',
    'tags',
    'title',
    'url',
  ]

  def __init__(self,args={}):
    CoreClass.__init__(self,args)

  def _record(self):
    r = self.__dict__
    return r

  def _file(self,ref = {}):

    file_a = self._file_a(ref)
    if not len(file_a):
      return

  def _file_a(self,ref = {}):
    sec  = ref.get('sec',self.sec)
    proj = ref.get('proj',self.proj)

    if sec and proj:
      return []

    runext = 'sh' 

    sfile_a = []
    if sec == '_main_':
      sfile_a = [ f'{proj}.tex' ]

    elif sec == '_vim_':
      sfile_a = [ f'{proj}.vim' ]

    elif sec == '_zlan_':
      sfile_a = [ f'{proj}.zlan' ]

    elif re.search(r'^_bld\.', sec):
      
      target = re.sub(r'^_bld\.(.*)$', r'\1', sec)
      sfile_a = [ f'{proj}.bld.{target}.yml' ]

    elif sec == '_yml_':
      sfile_a = [ f'{proj}.yml' ]

    elif re.search(r'^_perl\.', sec):

      sec = re.sub(r'^_perl\.(.*)$', r'\1', sec)
      sfile_a = [ f'{proj}.{sec}.pl' ]

    elif re.search(r'^_pm\.', sec):

      sec = re.sub(r'^_pm\.(.*)$', r'\1', sec)
      sfile_a = [ 'perl', 'lib', 'projs', root_id, proj, f'{sec}.pm' ]

    elif sec == '_pl_':
      sfile_a = [ f'{proj}.pl' ]

    elif sec == '_sql_':
      sfile_a = [ f'{proj}.sql' ]

    elif sec == '_xml_':
      sfile_a = [ f'{proj}.xml' ]

    elif sec == '_osecs_':
      sfile_a = [ f'{proj}.secorder.i.dat']

    elif sec == '_dat_':
      sfile_a = [ f'{proj}.secs.i.dat' ]

    elif sec == '_ii_include_':
      sfile_a = [ f'{proj}.ii_include.i.dat' ]

    elif sec == '_ii_exclude_':
      sfile_a = [ f'{proj}.ii_exclude.i.dat' ]

    elif sec == '_dat_defs_':
      sfile_a = [ f'{proj}.defs.i.dat' ]

    elif sec == '_dat_files_':
      sfile_a = [ f'{proj}.files.i.dat' ]

    elif sec == '_dat_files_ext_':
      sfile_a = [ f'{proj}.files_ext.i.dat' ]

    elif sec == '_dat_citn_':
      sfile_a = [ f'{proj}.citn.i.dat' ]

    elif sec == '_bib_':
      sfile_a = [ f'{proj}.refs.bib']

    elif sec == '_tex_jnd_':
      sfile_a = [ 'builds', proj, 'src', 'jnd.tex' ]

    elif sec == '_join_':
      sfile_a = [ 'joins', f'{proj}.tex' ]

    elif sec == '_build_pdflatex_':
      sfile_a = [ f'b_{proj}_pdflatex.{runext}' ]

    elif sec == '_build_perltex_':
      sfile_a = [ f'b_{proj}_perltex.{runext}' ]

    elif sec == '_build_htlatex_':
      sfile_a = [ f'b_{proj}_htlatex.{runext}' ]

    elif sec == '_main_htlatex_':
      sfile_a = [ f'{proj}.main_htlatex.tex' ]

    else:
      sfile_a = [ f'{proj}.{sec}.tex' ]


    return sfile_a
