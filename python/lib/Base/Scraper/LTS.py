
import os,re,sys

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

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

  def __init__(self,args={}):
    self.lts_root  = os.environ.get('P_SR')
    self.proj      = 'letopis'

    for k, v in args.items():
      setattr(self, k, v)

  def _sec_file(self,ref = {}):
    sec = ref.get('sec','')

    sec_file = os.path.join( self.lts_root, f'{self.proj}.{sec}.tex' )

    return sec_file

  def _author_id_merge(self,ids_in=[]):
    ids_merged = []
    for id in ids_in:
      ids = string.split_n_trim(id, sep = ',')
      ids_merged.extend(ids)

    ids_merged = util.uniq(ids_merged)
    ids_merged_s = ','.join(ids_merged)

    return ids_merged_s

  def author_add(self,ref={}):
    sec       = ref.get('sec','')
    author_id = ref.get('author_id','')

    sec_file = self._sec_file({ 'sec' : sec })

    if os.path.isfile(sec_file):
      nlines = []
      with open(sec_file,'r') as f:
        lines = f.readlines()
        flags = {}
        for line in lines:
          line = line.strip('\n')

          if re.match('%%beginhead\s*$',line):
            flags['head'] = 1
          if re.match('%%endhead\s*$',line):
            if 'head' in flags:
              del flags['head']
            #flags['head'] = 0

          m = re.match(r'^\s*\\(part|chapter|section|subsection|subsubsection|paragraph)\{(.*)\}\s*$',line)
          if m:
            if not flags.get('seccmd'):
              flags['seccmd'] = m.group(1)
              flags['sectitle'] = m.group(2)

          if flags.get('head'):
            m = re.match('%%author_id\s+(.*)$',line)
            if m:
              a_id = m.group(1)
              ids_merged = self._author_id_merge([ a_id, author_id ])
              line = f'%%author_id {ids_merged}'

          if flags.get('seccmd'):
            m = re.match(r'^\\ifcmt\s*$',line)
            if m:
              flags['is_cmt'] = 1

            if flags.get('is_cmt'):
              if re.match(r'^\\fi\s*$',line):
                del flags['is_cmt']

              if re.match(r'^\s*author_begin\s*$',line):
                flags['cmt_author'] = 1

              if flags.get('cmt_author'):
                if re.match(r'^\s*author_end\s*$',line):
                  del flags['cmt_author']

                m = re.match(r'^(\s*)author_id\s+(.*)$',line)
                if m:
                  indent = m.group(1)
                  a_id = m.group(2)
                  ids_merged = self._author_id_merge([ a_id, author_id ])
                  line = f'{indent}author_id {ids_merged}'

          nlines.append(line)

        print(flags)

    with open(sec_file, 'w', encoding='utf8') as f:
      f.write('\n'.join(nlines) + '\n')

    return self

  def c_run(self,ref = {}):

    for d_act in self.acts:
      act  = d_act.get('act','')
      args = d_act.get('args',[])

      print(act)
      print(args)

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
