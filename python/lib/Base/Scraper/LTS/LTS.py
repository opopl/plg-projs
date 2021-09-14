
import os,re,sys
from pathlib import Path

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Re as ree
import plg.projs.db as projs_db

from plg.projs.Prj import Prj

import jinja2

import yaml

from Extern.Pylatex import Package
from Extern.Pylatex.base_classes import Command, Options

#from pylatex import Package
#from pylatex.base_classes import Command, Options

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
       'arr' : '-a --act',
       'kwd' : { 'help'    : 'Actions' }
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
    self.img_root  = os.environ.get('IMG_ROOT')

    self.proj      = 'letopis'
    self.rootid    = 'p_sr'

    self.db_file_pages = os.path.join(self.html_root,'h.db')
    self.db_file_projs = os.path.join(self.lts_root,'projs.sqlite')
    self.db_file_img   = os.path.join(self.img_root,'img.db')

    self.db_files = {
       'img'   : self.db_file_img,
       'pages' : self.db_file_pages,
       'projs' : self.db_file_projs,
    }

    self.cfg = {
       'fbicons' : {
          'width_tex' : 0.03
       }
    }

    self.prj = Prj({ 
      'proj'     : self.proj,
      'rootid'   : self.rootid,
      'root'     : self.lts_root,
      'db_file'  : self.db_file_projs,
      'db_files' : self.db_files,
    })

    for k, v in args.items():
      setattr(self, k, v)

    self.init()

  def init(self):

    acts = [
      [ 'init_dirs' ],
      [ 'init_tmpl' ],
    ]

    util.call(self,acts)

    return self

  def init_dirs(self):

    plg = os.environ.get('PLG')
    self.dirs.update({ 
      'plg' : plg 
    })

    if not self._dir('bin'):
      if self._file('script'):
        self.dirs.update({
            'bin' : str(Path(self._file('script')).parent),
        })
      else:
        if plg:
          self.dirs.update({
            'plg' : plg,
            'bin' : os.path.join(plg,'projs web_scraping py3'),
          })

    if not util.get(self,'dirs.tmpl'):
      self.dirs['tmpl'] = os.path.join(self._dir('bin'),'tmpl')

    self.dirs.update({
      'lts_root'  : self.lts_root,
      'html_root' : self.html_root,
      'img_root'  : self.img_root,
    })

    plg = os.environ.get('PLG')
    self.dirs.update({
      'tex' : {
         'preambles' : self._dir('plg','lts data tex preambles')
      }
    })

    return self

  def init_tmpl(self):

    env_tex  = jinja2.Environment(
      block_start_string = '\BLOCK{',
      block_end_string = '}',
      variable_start_string = '\VAR{',
      variable_end_string = '}',
      comment_start_string = '\#{',
      comment_end_string = '}',
      line_statement_prefix = '@@',
      line_comment_prefix = '%#',
      trim_blocks = True,
      autoescape = False,
      loader = jinja2.FileSystemLoader(searchpath=self._dir('tmpl','tex'))
    )

    self.template_env_tex = env_tex

    return self

  def _sec_tex_header(self,ref = {}):
    return t

  def _sec_file_data(self,ref = {}):
    sec = ref.get('sec','')

    sec_file = self._sec_file({ 'sec' : sec })
    data = projs_db.get_data(sec_file)

    return data

  def _sec_file(self,ref = {}):
    sec = ref.get('sec','')

    sec_file = os.path.join( self.lts_root, f'{self.proj}.{sec}.tex' )

    return sec_file

  def _auth_data(self, ref = {}):
    fb_id     = ref.get('fb_id','')

    author_id = ref.get('id','')

    auth = None

    if not author_id:
      if fb_id:
        cols_d = dbw._cols({ 
            'table'   : 'auth_details',
            'db_file' : self.db_file_pages
        })
  
        author_id = dbw.sql_fetchval('''SELECT id FROM auth_details WHERE fb_id = ? ''',[ fb_id ],
           { 'db_file' : self.db_file_pages })

    if author_id:
      auth = { 
        'id' : author_id 
      }

      rw = dbw.sql_fetchone('''SELECT * FROM authors WHERE id = ? ''',
         [ author_id ],
         { 'db_file' : self.db_file_pages })
      row  = rw.get('row',{})
      cols = rw.get('cols',[])
      for col in cols:
        auth[col] = row.get(col)

      for col in cols_d:
        if col in ['id']:
          continue

        vallist = dbw.sql_fetchlist(f'''SELECT {col} FROM auth_details WHERE id = ?''',
           [ author_id ],
           { 'db_file' : self.db_file_pages })

        val = None
        if vallist and (len(vallist) == 1) and (vallist[0] == None):
          pass
        else:
          val = vallist

        auth[col] = val

    return auth

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

  def vimtags_db_create(self, ref = {}):
    db_file = self.db_file_projs

    return self

  def vimtags_update(self, ref = {}):
    tfile = os.path.join(self.lts_root,'letopis.tags')

    db_file = self.db_file_projs
    tb = 'projs'

    self.vimtags_db_create()

    tlines = []

    q = f'''SELECT sec, file FROM {tb} WHERE proj = ? ORDER BY sec '''
    proj = 'letopis'

    r = dbw.sql_fetchall(q,[ proj ],{ 'db_file' : db_file })
    rows = r.get('rows')

    for rw in rows:
      sec  = rw.get('sec','')
      file = rw.get('file','')
      if not ( sec and file ):
        continue

      file_path = os.path.join(self.lts_root,file)
      if not os.path.isfile(file_path):
        print(file_path)
        dbw.delete({ 
          'where'   : { 'sec' : sec, 'proj' : proj },
          'db_file' : db_file,
          'table'   : tb
        })
        continue

      tline = f'''{sec}\t{file_path}\t1'''
      tlines.append(tline)

    ttext = '''!_TAG_FILE_FORMAT 2 /extended format; --format=1 will not append ;" to lines/
!_TAG_FILE_SORTED 1 /0=unsorted, 1=sorted, 2=foldcase/
!_TAG_PROGRAM_AUTHOR  Darren Hiebert  /dhiebert@users.sourceforge.net/
!_TAG_PROGRAM_NAME  Exuberant Ctags //
!_TAG_PROGRAM_URL http://ctags.sourceforge.net  /official site/
!_TAG_PROGRAM_VERSION 5.8 //
'''
    ttext += '\n'.join(tlines) + '\n'
    with open(tfile, 'w', encoding='utf8') as f:
      f.write(ttext)

    return self

  def db_sql_do(self, ref = {}):
    db_id   = ref.get('db_id','')
    db_file = self.db_files.get(db_id,'')

    sql_cmds = ref.get('sql_cmds',[])

    if not db_file:
      return self

    for sql_cmd in sql_cmds:
      print(sql_cmd)
      dbw.sql_do({
        'db_file' : db_file,
        'sql'     : sql_cmd,
      })

    return self

  def _tex_tmpl_render(self, tmpl='', ref={}):
    t = self.template_env_tex.get_template(tmpl)
    text = t.render(**ref)

    return text

  def db_secs_list(self, ref = {}):
    pat  = ref.get('pat','')
    ext  = ref.get('ext','')

    secs = self.prj._sections({ 
      'pat' : pat,
      'ext' : ext,
    })

    for sec in secs:
      print(sec)

    return self

  def _tex_preamble_names(self, ref = {}):
    dir = self._dir('tex.preambles','')
    names = util.find({ 
      'dirs' : [dir],
      'inc'  : 'dir',
      'relpath'  : 1,
    })
    return names

  def _tex_head(self, ref = {}):
    t = self._tex_tmpl_render('head.tex',ref)

    tex_lines = t.split('\n')
    return tex_lines

  def _tex_preamble(self, ref = {}):
    r_preamble = ref.get('preamble',{})

    if not len(r_preamble):
      # preamble name
      name = ref.get('name','')
      if name:
        names = self._tex_preamble_names()
        if name in names:
          dir = self._dir('tex.preambles',name)
          pack_file = os.path.join(dir,'packs.yaml')
          if os.path.isfile(pack_file):
            r_preamble = { 'pack_file' : pack_file }

    if not len(r_preamble):
      return self

    tex_lines = []

    pack_file = r_preamble.get('pack_file','')
    pack_data = {}
    if os.path.isfile(pack_file):
      with open(pack_file) as f:
        pack_data = yaml.full_load(f)

    if len(pack_data):
      pack_list    = pack_data.get('list',[])
      pack_options = pack_data.get('options',{})

      for pack in pack_list:
        opts = pack_options.get(pack,{})

        opts_bool = []
        opts_dict = {}
        for k, v in opts.items():
           if type(v) in [bool] and v == True:
             opts_bool.append(k)
           else:
             opts_dict.update({ k : v })

        s = Package(pack,options=Options(*opts_bool, **opts_dict)).dumps()
        tex_lines.append(s)

    return tex_lines

  def tex_compile(self, ref = {}):


    return self

  # given section name, simply create it:
  #    write to file, add to database
  def sec_new(self, ref = {}):
    sec = ref.get('sec','')
    if not sec:
      return self

    s_head = self._tex_tmpl_render('head.tex',ref)
    s_content = self._tex_tmpl_render('sec.tex',ref)

    s = '\n'.join([ s_head, s_content ]) + '\n'

    sec_file = self._sec_file({ 'sec' : sec })
    with open(sec_file, 'w', encoding='utf8') as f:
      f.write(s)

    return self

  def sec_new_date(self, ref = {}):
    date      = ref.get('date','')

    return self

  def _fbicons_db(self):
    db_file  = self.db_file_img

    names = dbw.select({ 
      'table'   : 'imgs',
      'db_file' : db_file,
      'select' : 'name',
      'orderby' : { 'name' : 'asc' },
      'output' : 'list',
      'where' : { 
         '@like' : { 'name' : 'fbicon%' }
      }
    })
    fbicons = []
    for name in names:
      m = re.match(r'^fbicon\.(.*)$',name)
      if m:
        fbi = m.group(1)
        fbicons.append(fbi)
        
    return fbicons

  def _fbicon_db(self, ref = {}):
    db_file  = self.db_file_img

    name = ref.get('name')

    rw = dbw.select({ 
      'table'   : 'imgs',
      'db_file' : db_file,
      'output' : 'first_row',
      'where' : { 'name' : name }
    })

    img = rw.get('img')
    if img:
      rw.update({ 
         'img_file' : self._dir('img_root',[ img ])
      })

    return rw

  def _tex_ig(self, ref = {}):
    width = ref.get('width')
    file  = ref.get('file')

    if not os.path.isfile(file):
      ig = ''
    else:
      iga = [
        f'''\\includegraphics[width={width}\\textwidth]''',
        '{', file, '}'
      ]
      ig = ''.join(iga)

    return ig

  def db_fbicons_list(self, ref = {}):
    width_tex = util.get(self,'cfg.fbicons.width_tex',0.05)

    sec = 'list.fbicons'
    list_file = self._sec_file({ 'sec' : sec })

    fbicons = self._fbicons_db()

    tex_preamble = self._tex_preamble({ 
      'name' : 'core' 
    })

    tex_head = self._tex_head({ 
      'sec' : sec
    })
    tex_lines = []
    tex_lines.extend(tex_head)

    tex_lines.append('\\begin{tabular}{*{2}{l}}')

    tex_tab_rows = []
    for fbi in fbicons:
      name = f'fbicon.{fbi}'
      fbi_data = self._fbicon_db({ 'name' : name })
      img_file  = fbi_data.get('img_file','')
      wt = fbi_data.get('width_tex',width_tex)
      ig = self._tex_ig({ 
        'file'  : img_file,
        'width' : wt,
      })

      tex_row = ' & '.join([ ig, fbi ]) + '\\\\'
      tex_lines.append(tex_row)

    tex = tex_lines.append('\\end{tabular}')

    tex = '\n'.join(tex_lines) + '\n'
    with open(list_file, 'w', encoding='utf8') as f:
      f.write(tex)

    return self

  def db_fbicons_update(self, ref = {}):
    db_file  = self.db_file_img

    width_tex = util.get(self,'cfg.fbicons.width_tex',0.05)

    q = '''SELECT * FROM imgs WHERE name LIKE 'fbicon%' '''
    r = dbw.sql_fetchall(q,[ ],{ 'db_file' : db_file })
    rows = r.get('rows',[])
    for rw in rows:
      name = rw.get('name')
      dbw.update_dict({ 
         'db_file' : db_file,
         'table' : 'imgs',
         'update' : { 'width_tex' : width_tex },
         'where' : { 'name' : name },
      })

    return self

  def db_update_img(self, ref = {}):
    img_data = ref.get('img_data',[])
    db_file  = self.db_file_img

    for d_img in img_data:
      url = d_img.get('url','')
      if not url:
        continue

      d = {
        'db_file' : db_file,
        'table'   : 'imgs',
        'insert'  : d_img,
        'on_list' : [ 'url' ]
      }

      dbw.insert_update_dict(d)

    return self

  def import_auth2db(self, ref = {}):
    authors_file = os.path.join(self.lts_root,'data', 'dict', 'authors.i.dat')
    fb_authors_file = os.path.join(self.lts_root,'data', 'dict', 'fb_authors.i.dat')

    names_file = os.path.join(self.lts_root,'scrape','bs','in','lists','names_first.i.dat')
    names_first = util.readarr(names_file)

    fb_authors = util.readdict(fb_authors_file)

    home = os.environ.get('HOME')
    #db_file = os.path.join(home,'tmp','h.db')

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
              'db_file' : self.db_file_pages,
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
              'db_file' : self.db_file_pages,
              'table'   : 'auth_details',
              'insert'  : d_auth_detail,
              'on_list' : [ 'id', 'fb_id' ]
            }
            dbw.insert_update_dict(d)

    r_db = { 'db_file' : self.db_file_pages }

    cnt = {}
    for t in util.qw('authors auth_details'):
      cnt[t] = dbw.sql_fetchval(f'select count(*) from {t}',[],r_db)

    print(f'Count(authors):      {cnt["authors"]}')
    print(f'Count(auth_details): {cnt["auth_details"]}')

    return self

  #let cnt = projs#sec#count_ii({ 'ii_prefix' : ii_prefix })
  def _sec_count_ii(self, ref = {}):
    ii_prefix = ref.get('ii_prefix','')

    q = f'''SELECT COUNT(*) FROM projs WHERE sec LIKE "{ii_prefix}%%" '''

    cnt = dbw.sql_fetchval(q,[],{ 'db_file' : self.db_file_projs })

    return cnt

  def _fb_data(self, ref = {}):
    url       = ref.get('url','')

    u = util.url_parse(url)
    fb_data = None

    m = ree.search('url.facebook.base',u['host'])
    if not m:
      return

    fb_id = None
    post_id = None

    if ree.match('url.facebook.permalink',u['path']):
      fb_id   = u['query_p'].get('id','') 
      post_id = u['query_p'].get('story_fbid','') 

      if fb_id and post_id:
         url = util.url_join('https://www.facebook.com',f'/{fb_id}/posts/{post_id}')
         u = util.url_parse(url)

    else:
      m_path = ree.match('url.facebook.post_user',u['path'])

      if m_path:
        fb_id = m_path.group(1)
        post_id = m_path.group(2)

    fb_data = { 
      'fb_id'   : fb_id,
      'post_id' : post_id,
    }

    return fb_data

  def _sec_ii_prefix(self, ref = {}):
    parent    = ref.get('parent','')
    url       = ref.get('url','')

    author_id = ref.get('author_id','')

    ii_prefix = f'{parent}.'

    fb_data = self._fb_data({ 'url' : url })
    if fb_data:
      fb_id = fb_data.get('fb_id','')

      if fb_id:
        auth = self._auth_data({ 'fb_id' : fb_id })
        if auth:
          author_id = auth.get('id')
    
    if author_id:
      ii_prefix = f'{ii_prefix}fb.{author_id}.'

    cnt = self._sec_count_ii({ 'ii_prefix' : ii_prefix })
    inum = cnt + 1

    ii_prefix = f'{ii_prefix}{inum}.'

    return ii_prefix

  def sec_new_ii_url(self, ref = {}):
    # parent section
    parent    = ref.get('parent','')

    url       = ref.get('url','')
    title     = ref.get('title','')
    author_id = ref.get('author_id','')

    # section to be created
    sec       = ref.get('sec','')

    # final part of the section full name
    ii_sec    = ref.get('ii_sec','')

    date      = ref.get('date','')

    tags      = ref.get('tags','')

    seccmd    = ref.get('seccmd','')

    ii_prefix = self._sec_ii_prefix({ 
      'parent' : parent,
      'url'    : url,
    })

    print(f'ii_prefix => {ii_prefix}')

    t = self.template_env_tex.get_template("sec.tex")

    h = t.render(
        author_id = author_id,
        date = date,
        parent = parent,
        sec = sec,
        seccmd = seccmd,
        tags = tags,
        title = title,
        url = url,
    )

    sec_file = self._sec_file({ 'sec' : sec })

    #print(h)

    return self

  def _fbauth_list_fs(self):
    fbauth_secs = self._fbauth_secs_fs()
    fbauth_list = []
    for sec in fbauth_secs:
      m = re.match(r'fbauth\.(.*)$',sec)
      if m:
        fba = m.group(1)
        fbauth_list.append(fba)

    return fbauth_list

  def _fbauth_secs_fs(self):
    p = Path(self._dir('lts_root'))

    fbauth_secs = []
    for pp in p.glob(f'{self.proj}.fbauth.*.tex'):
      pp_file = pp.name
      m = re.match(rf'^{self.proj}\.(.*)\.tex$',pp_file)
      if not m:
        continue

      sec = m.group(1)
      fbauth_secs.append(sec)

    fbauth_secs.sort()

    return fbauth_secs

  def fbauth_list_fs(self, ref = {}):
    fbauth_list = self._fbauth_list_fs()
    for fba in fbauth_list:
      print(fba)

    return self

#http://eosrei.net/articles/2015/11/latex-templates-python-and-jinja2-generate-pdfs
#https://web.archive.org/web/20121024021221/http://e6h.de/post/11/
  def fbauth_create(self, ref = {}):
    lines = []

    fba = ref.get('fba','')
    if not fba:
      return self

    head_data   = ref.get('head_data',{})
    fbauth_data = ref.get('fbauth_data',{})

    fbauth_data = util.dict_str2int(fbauth_data, keys = [ 'friend' ])
    fbauth_data = util.dict_none2str(fbauth_data)
    #fbauth_data = util.dict_none_rm(fbauth_data)

    t = self.template_env_tex.get_template("head.tex")
    s_head = t.render(**head_data)

    t = self.template_env_tex.get_template("fbauth.tex")
    s_fbauth = t.render(**fbauth_data)

    lines.extend(s_head.split('\n'))
    lines.extend([ '' ])
    lines.extend(string.split_n_trim(s_fbauth))
    #lines.extend(s_fbauth.split('\n'))

    t = '\n'.join(lines) + '\n'

    sec = f'''fbauth.{fba}'''
    sec_file = self._sec_file({ 'sec' : sec })

    with open(sec_file, 'w', encoding='utf8') as f:
      f.write(t)

    insert = {
      'sec'    : sec,
      'proj'   : self.proj,
      'rootid' : self.rootid,
      'file'   : Path(sec_file).name,
    }

    dbw.insert_dict({ 
      'db_file' : self.db_file_projs,
      'table'  : 'projs',
      'insert' : insert
    })

    return self

  def fbauth_join(self, ref = {}):
    f_join = self._dir('lts_root',f'{self.proj}.fbauth_join.tex')

    lines_join = []

    fbauth_secs = self._fbauth_secs_fs()
    for sec in fbauth_secs:
      lines_join.append('\ii{%s}' % sec)

    text_join = '\n'.join(lines_join) + '\n'

    with open(f_join, 'w', encoding='utf8') as f:
      f.write(text_join)

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

    self.sec_author_file2db({ 'sec' : sec })

    return self

  def sec_author_file2db(self, ref = {}):
    sec       = ref.get('sec','')

    where = {
      'sec'  : sec,
      'proj' : self.proj,
    }

    data = self._sec_file_data({ 'sec' : sec })
    author_id_new = data.get('author_id','')
    dbw.update_dict({
      'db_file' : self.db_file_projs,
      'table' : 'projs',
      'update' : {
         'author_id' : author_id_new
      },
      'where' : where
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

    self.sec_author_file2db({ 'sec' : sec })

    return self

  def c_run(self,ref = {}):

    for d_act in self.acts:
      act = d_act
      args = []
      if type(d_act) in [dict]:
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

    for k in util.qw('act'):
      v  = util.get(self,[ 'oa', k ])
      if v:
        acts = string.split_n_trim(v, sep = ',' )
        for act in acts:
          self.acts.append({ 'act' : act })

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
