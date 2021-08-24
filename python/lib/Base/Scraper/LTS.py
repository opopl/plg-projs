
import os,re,sys

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Re as ree

from Base.Mix.mixCmdRunner import mixCmdRunner
from Base.Mix.mixLogger import mixLogger
from Base.Mix.mixLoader import mixLoader
from Base.Mix.mixGetOpt import mixGetOpt
from Base.Mix.mixFileSys import mixFileSys

from Base.Zlan import Zlan
from Base.Core import CoreClass

class LTS(
     CoreClass,
     mixLogger,
     mixCmdRunner,
     mixGetOpt,
     mixLoader,
     mixFileSys,
  ):

  usage='''
  PURPOSE
        This script is for handling LTS
  '''

  opts_argparse = [
    {
       'arr' : '-c --cmd',
       'kwd' : { 'help'    : 'Run command(s)' }
    },
    { 
       'arr' : '-y --f_yaml', 
       'kwd' : { 
           'help'    : 'input YAML file',
           'default' : '',
       } 
    },
  ]

  vars = {
    'mixCmdRunner' : {
      'cmds' : []
    }
  }

  acts = []

  line = None
  lines = []
  nlines = []

  def __init__(self,args={}):
    self.lts_root  = os.environ.get('P_SR')
    self.proj      = 'letopis'

    for k, v in args.items():
      setattr(self, k, v)

  def _sec_file(self,ref = {}):
    sec = ref.get('sec','')

    sec_file = os.path.join( self.lts_root, f'{self.proj}.{sec}.tex' )

    return sec_file

  def _author_id_remove(self, ids_in = [], ids_remove = []):

    ids_in_a     = []
    ids_remove_a = []

    ids_new_a    = []

    for id in ids_in:
      ids = string.split_n_trim(id, sep = ',')
      ids_in_a.extend(ids)

    for id in ids_remove:
      ids = string.split_n_trim(id, sep = ',')
      ids_remove_a.extend(ids)

    for id in ids_in_a:
      if not id in ids_remove_a:
        ids_new_a.append(id)

    ids_new_a = util.uniq(ids_new_a)
    ids_new   = ','.join(ids_new_a)

    return ids_new

  def _author_id_merge(self,ids_in = []):
    ids_merged = []
    for id in ids_in:
      ids = string.split_n_trim(id, sep = ',')
      ids_merged.extend(ids)

    ids_merged = util.uniq(ids_merged)
    ids_merged_s = ','.join(ids_merged)

    return ids_merged_s

  def lines_tex_process(self,ref={}):
    if not self.lines:
      return self

    actions = ref.get('actions',[])

    self.nlines = []
    flags = {}

    while len(self.lines):
      self.line = self.lines.pop(0)

      self.line = self.line.strip('\n')

      if ree.match('tex.projs.beginhead', self.line):
        flags['head'] = 1
      if ree.match('tex.projs.endhead', self.line):
        if 'head' in flags:
          del flags['head']

      m = ree.match('tex.projs.seccmd', self.line)
      if m:
        if not flags.get('seccmd'):
          flags['seccmd'] = m.group(1)
          flags['sectitle'] = m.group(2)

      if flags.get('head'):
        m = ree.match('tex.projs.author_id',self.line)
        if m:
          a_id = m.group(1)

          for action in actions:
            name = action.get('name','')
            args = action.get('args',[])

            if name in [ '_author_id_merge' ]:
              if len(args):
                author_id  = args[0].get('author_id','')
                if author_id:
                  ids_merged = util.call(self, name, [ [ a_id, author_id ] ])
                  self.line = f'%%author_id {ids_merged}'

            if name in [ '_author_id_remove' ]:
              if len(args):
                author_id  = args[0].get('author_id','')
                if author_id:
                  ids_new = util.call(self, name, [ [ a_id ] , [ author_id ] ])
                  self.line = f'%%author_id {ids_new}'

      if flags.get('seccmd'):
        m = ree.match('tex.projs.ifcmt',self.line)
        if m:
          flags['is_cmt'] = 1

        if flags.get('is_cmt'):
          if ree.match('tex.projs.fi',self.line):
            del flags['is_cmt']

          if ree.match('tex.projs.cmt.author_begin',self.line):
            flags['cmt_author'] = 1

          if flags.get('cmt_author'):
            if ree.match('tex.projs.cmt.author_end',self.line):
              del flags['cmt_author']

            m = ree.match('tex.projs.cmt.author_id',self.line)
            if m:
              indent = m.group(1)
              a_id = m.group(2)

              for action in actions:
                name = action.get('name','')
                args = action.get('args',[])

                if name in [ '_author_id_merge' ]:
                  if len(args):
                    author_id  = args[0].get('author_id','')
                    if author_id:
                      ids_merged = util.call(self, name, [ [ a_id, author_id ] ])
                      self.line = f'{indent}author_id {ids_merged}'

                if name in [ '_author_id_remove' ]:
                  if len(args):
                    author_id  = args[0].get('author_id','')
                    if author_id:
                      ids_new = util.call(self, name, [ [ a_id ], [ author_id ] ])
                      self.line = f'{indent}author_id {ids_new}'

      self.nlines.append(self.line)

    return self

  def sec_process(self,ref={}):
    sec       = ref.get('sec','')

    lines_ref = ref.get('lines',{})

    sec_file = self._sec_file({ 'sec' : sec })

    if os.path.isfile(sec_file):
      self.nlines = []
      with open(sec_file,'r') as f:
        self.lines = f.readlines()
        self.lines_tex_process(lines_ref)

    with open(sec_file, 'w', encoding='utf8') as f:
      f.write('\n'.join(self.nlines) + '\n')

    return self

  def author_add(self,ref={}):
    sec       = ref.get('sec','')
    author_id = ref.get('author_id','')

    lines_ref = {
      'actions' : [
          {
            'name' : '_author_id_merge',
            'args' : [ { 'author_id' : author_id } ]
          }
       ]
    }

    self.sec_process({
      'lines' : lines_ref,
      'sec'   : sec,
    })

    return self

  def author_rm(self,ref={}):
    sec       = ref.get('sec','')
    author_id = ref.get('author_id','')

    lines_ref = {
      'actions' : [
          {
            'name' : '_author_id_remove',
            'args' : [ { 'author_id' : author_id } ]
          }
       ]
    }

    self.sec_process({
      'lines' : lines_ref,
      'sec'   : sec,
    })

    return self

  def c_run(self,ref = {}):

    for d_act in self.acts:
      act  = d_act.get('act','')
      args = d_act.get('args',[])

      util.call(self, act, args)

    return self

  def get_opt_apply(self):
    if not self.oa:
      return self

    for k in util.qw('f_yaml'):
      v  = util.get(self,[ 'oa', k ])
      m = re.match(r'^f_(\w+)$', k)
      if m:
        ftype = m.group(1)
        self.files.update({ ftype : v })

    return self

  def get_opt(self):
    if self.skip_get_opt:
      return self

    mixGetOpt.get_opt(self)

    self.get_opt_apply()

    return self

  def main(self):

    acts = [
      [ 'get_opt' ],
      [ 'load_yaml' ],
      [ 'do_cmd' ],
    ]

    util.call(self,acts)
