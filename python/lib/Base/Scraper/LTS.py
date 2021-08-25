
import os,re,sys

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Re as ree

import jinja2

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
    self.html_root = os.environ.get('HTML_ROOT')

    self.proj      = 'letopis'

    for k, v in args.items():
      setattr(self, k, v)

  def _sec_tex_header(self,ref = {}):
    return t

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

  def import_auth2db(self, ref = {}):
    authors_file = os.path.join(self.lts_root,'data', 'dict', 'authors.i.dat')
    fb_authors_file = os.path.join(self.lts_root,'data', 'dict', 'fb_authors.i.dat')

    names_file = os.path.join(self.lts_root,'scrape','bs','in','lists','names_first.i.dat')
    names_first = util.readarr(names_file)

    fb_authors = util.readdict(fb_authors_file)

    home = os.environ.get('HOME')
    #db_file = os.path.join(home,'tmp','h.db')
    db_file = os.path.join(self.html_root,'h.db')

    with open(authors_file,'r',encoding='utf8') as f:
      self.lines = f.readlines()
      while len(self.lines):
        self.line = self.lines.pop(0).strip('\n')
        if re.match(r'^#',self.line) or (len(self.line) == 0):
          continue

        m = ree.match('idat.dict',self.line)
        if m:
          author_id    = m.group(1)

          # facebook ids corresponding to single author_id
          fb_ids = []

          # incoming author string
          author_bare  = m.group(2)

          # plain author name
          author_plain = author_bare

          # inverted if needed
          author_name  = author_bare

          m = ree.match('author.bare.inverted',author_bare)
          if m:
            last_name  = m.group(1).strip()
            first_name = m.group(2).strip()
            author_plain = f'{first_name} {last_name}'
            if not first_name in names_first:
              author_name = author_plain

          for fb_id, a_id in fb_authors.items():
            if a_id == author_id:
              fb_ids.append(fb_id)

          # table: authors in html_root/h.db
          d_auth = {
            'id'    : author_id,
            'name'  : author_name,
            'plain' : author_plain,
          }

          d = {
              'db_file' : db_file,
              'table'   : 'authors',
              'insert'  : d_auth,
              'on_list' : [ 'id' ]
          }

          dbw.insert_update_dict(d)

          # table: auth_details in html_root/h.db
          for fb_id in fb_ids:
            d_auth_detail = {
              'id'     : author_id,
              'fb_url' : f'https://www.facebook.com/{fb_id}',
              'fb_id'  : fb_id,
            }

            d = {
              'db_file' : db_file,
              'table'   : 'auth_details',
              'insert'  : d_auth_detail,
              'on_list' : [ 'id', 'fb_id' ]
            }
            dbw.insert_update_dict(d)

    r_db = { 'db_file' : db_file }

    cnt = {}
    for t in util.qw('authors auth_details'):
      cnt[t] = dbw.sql_fetchval(f'select count(*) from {t}',[],r_db)

    print(f'Count(authors):      {cnt["authors"]}')
    print(f'Count(auth_details): {cnt["auth_details"]}')

    return self

  def sec_new_ii_url(self, ref = {}):
    # parent section
    sec       = ref.get('sec','')

    url       = ref.get('url','')
    title     = ref.get('title','')
    author_id = ref.get('author_id','')

    return self

  def sec_author_add(self, ref = {}):
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

  def sec_author_rm(self, ref = {}):
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
