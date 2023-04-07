
import re
import os
import sqlite3
import sqlparse
import sys

import Base.DBW as dbw
import Base.Util as util

from pathlib import Path

from dict_recursive_update import recursive_update
from tabulate import tabulate

#import pprint
#pp = pprint.PrettyPrinter(indent=4)

p = {
    'tex_file'   : re.compile('^(\w+)\.(?:(.*)\.|)tex'),
    'proj_file'  : re.compile('^(\w+)\.(?:(.*)\.|)(tex|pl|vim)'),
    'tags'       : re.compile('^\s*%%tags (.*)$'),
    'author'     : re.compile('^\s*%%author (.*)$'),
    'author_id'  : re.compile('^\s*%%author_id (.*)$'),
    'url'        : re.compile('^\s*%%url (.*)$'),
    'title'      : re.compile('^\s*%%title (.*)$'),
    'parent'     : re.compile('^\s*%%parent (.*)$'),
}

p_keys = util.qw('tags author_id url title')

def create_tables(db_file, sql_file):
  conn = sqlite3.connect(db_file)
  c = conn.cursor()

  sql = open(sql_file, 'r').read()
  for q in sqlparse.split(sql):
    try:
        c.execute(q)
    except sqlite3.OperationalError as e:
        print(e)
    except:
        print("Errors ",sys.exc_info()[0]," for sqlite query: " + q )

  conn.commit()
  conn.close()

def author_add(r):
  db_file   = r.get('db_file')

  author    = r.get('author')
  author_id = r.get('author_id')

  conn = sqlite3.connect(db_file)
  dbw.insert_dict({
    'conn'      : conn,
    'table'     : 'authors',
    'insert'  : {
      'author'    : author,
      'author_id' : author_id
    }
  })

  conn.commit()
  conn.close()

def sql_file_exec(db_file, sql_file):
  conn = sqlite3.connect(db_file)
  c = conn.cursor()

  sql = open(sql_file, 'r').read()
  for q in sqlparse.split(sql):
    try:
        c.execute(q)
    except sqlite3.OperationalError as e:
        print(e)
    except:
        print("Errors ", sys.exc_info()[0], " for sqlite query: " + q )

  conn.commit()
  conn.close()

def drop_tbl(r):
  db_file = r.get('db_file')
  tbl     = r.get('tbl')

  if not tbl:
    return

  tables = [ x.strip() for x in tbl.split(',') if x ]

  conn = sqlite3.connect(db_file)
  for t in tables:
    print('''Dropping table in db: %s, table: %s ''' % (db_file,t) )
    c = conn.cursor()

    c.execute('''DROP TABLE IF EXISTS %s''' % t)

  conn.commit()
  conn.close()

def get_data(filename):
  data = {}

  lines = []
  try:
    lines = open(filename,'rb')
  except PermissionError as e:
    print(e, filename)
    return data

  for ln in lines:
    line = ''
    try:
      line = ln.decode('utf-8').strip('\n')
    except UnicodeDecodeError as e:
      print(e,filename)
    if line:
      for k in p_keys:
        m = p[k].match(line)
        if m:
           data[k] = m.group(1)
  return data

def cleanup(db_file, root, proj):
  conn = sqlite3.connect(db_file)
  c = conn.cursor()

  q='''SELECT file FROM projs WHERE proj = ?'''
  c.execute(q,[ proj ])
  rows = c.fetchall()
  for row in rows:
    file  = row[0]
    fpath = os.path.join(root,file)
    if not os.path.isfile(fpath):
      q = '''DELETE FROM projs WHERE proj = ? AND file = ?'''
      c.execute(q,[ proj, file ])

  conn.commit()
  conn.close()

def info(db_file):
  tb_list = dbw._tb_list({ 'db_file' : db_file })
  info = { 'cnt' : {} }

  for tbl in tb_list:
    q = f'SELECT COUNT(*) AS cnt FROM {tbl}'
    cnt = dbw.sql_fetchval(q,[],{ 'db_file' : db_file })
    recursive_update(info, util.dictnew(f'cnt.{tbl}',cnt))

  counts = info['cnt']
  info_cnt_data = []
  for tbl in counts.keys():
    count = counts[tbl]
    info_cnt_data.append([ tbl, count ])
  t = tabulate(info_cnt_data,headers = util.qw('table count'))
  print(t)

def fill_from_files(db_file = '', root = '', root_id = '', proj = '', logfun = '', exts = []):

  if len(proj):
    pt = re.compile('^(%s)\.(?:(.*)\.|)(\w+)$' % proj)
    print(f'''("{proj}" project) Filling tables in db: {db_file}''')
  else:
    pt = re.compile('^(\w+)\.(?:(.*)\.|)(\w+)$')
    print(f'''(all projects) Filling tables in db: {db_file}''')

  pt_bib   = re.compile('^(\w+)\.refs\.bib$')
  pt_bld_sec = re.compile('^bld\.(.*)$')
  pt_dat_i = re.compile('^(.*)\.i$')

  pfiles = []
  proot = Path(root)
  if len(exts):
    for ext in exts:
      found = list(proot.glob(f'*.{ext}'))
      pfiles.extend(found)
  else:
    pfiles.extend(proot.glob(f'*.{ext}'))

  x = 0
  i = 0
  h_projs = []
  for pfile in pfiles:
    i+=1
    file = pfile.name
    fpath = pfile.as_posix()
    m = pt.match(file)
    if not m:
      continue

    proj_m = m.group(1)
    ext    = m.group(3)
    x+=1
    if proj_m in ['bld']:
      continue

    if proj and not ( proj_m == proj ):
      continue

    sec    = m.group(2)

    if ext == 'tex':
      sec = sec if sec else '_main_'

    if ext == 'yml':
      if sec:
        m = pt_bld_sec.match(sec)
        if not m:
          sec = None
        else:
          target = m.group(1)
          sec = f'_bld.{target}'
          ins_trg = {
            'proj'      : proj_m,
            'target'    : target,
          }
          dbw.insert_update_dict({
              'db_file'  : db_file,
              'table'    : 'targets',
              'insert'   : ins_trg,
              'on_list'  : ['proj','target']
          })
      else:
        sec = '_yml_'

    if ext == 'pl':
      if not sec:
        continue
      else:
        sec = '_perl.%s' % sec

    if ext == 'dat':
        m = pt_dat_i.match(sec)
        if m:
            sec_m = re.sub(pt_dat_i,r'\1',sec)
            if sec_m == 'ii_include':
                sec = '_ii_include_'
            if sec_m == 'ii_exclude':
                sec = '_ii_exclude_'

    if ext == 'vim':
      if not sec:
        sec = '_vim_'

    if ext == 'bib':
      m_bib = pt_bib.match(file)
      if m_bib:
          sec = '_bib_'

    if not sec:
      continue

    data   = get_data(fpath)

    tags      = data.get('tags','')
    author_id = data.get('author_id','')
    url       = data.get('url','')

    ins = {
      'file'      : file,
      'author_id' : author_id,
      'proj'      : proj_m,
      'rootid'    : root_id,
      'sec'       : sec,
      'tags'      : tags,
      'url'       : url,
      'title'     : data.get('title',''),
      'parent'    : data.get('parent',''),
    }

    dbw.insert_update_dict({
        'db_file'  : db_file,
        'table'    : 'projs',
        'insert'   : ins,
        'on_list'  : ['file']
    })

#  c.execute('''SELECT DISTINCT proj FROM projs''')
  #rows = c.fetchall()
  #for row in rows:
    #proj = row[0]
    #dir_pm = os.path.join(root, 'perl', 'lib', 'projs', root_id, proj)
    #if os.path.isdir(dir_pm):
      #for (dirpath, dirnames, filenames) in os.walk(dir_pm):
        #for f in filenames:
            #file_pm = os.path.join(dir_pm,f)
            #pm_rel = os.path.relpath( file_pm, root )
            #(pm_head,pm_tail) = os.path.split(file_pm)
            #(pm_root,pm_ext) = os.path.splitext(pm_tail)
            #sec = '_pm.%s' % pm_root

            #dbw.insert_update_dict({
                #'conn'     : conn,
                #'table'    : 'projs',
                #'insert' : {
                  #'file'    : pm_rel,
                  #'proj'    : proj,
                  #'rootid'  : root_id,
                  #'sec'     : sec,
                 #},
                #'on_list' : ['file']
            #})
        #break

  return 1

