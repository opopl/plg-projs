
import sqlite3
import re
import os
import sqlparse,sys

#import pprint
#pp = pprint.PrettyPrinter(indent=4)

p = { 
    'tex_file'   : re.compile('^(\w+)\.(?:(.*)\.|)tex'), 
    'proj_file'  : re.compile('^(\w+)\.(?:(.*)\.|)(tex|pl|vim)'), 
    'tags'       : re.compile('^\s*%%tags (.*)$'),
    'author'     : re.compile('^\s*%%author (.*)$')
   }

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

def drop_tables(db_file):
  print('''Dropping tables in db: %s ''' % db_file)
  conn = sqlite3.connect(db_file)
  c = conn.cursor()
  
  c.execute('''DROP TABLE IF EXISTS projs''')
  
  conn.commit()
  conn.close()

def get_data(filename):
  data = {}
  with open(filename) as lines:
    for line in lines:
      m = p['tags'].match(line)
      if m:
        data['tags'] = m.group(1)
      m = p['author'].match(line)
      if m:
        data['author'] = m.group(1)
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

def insert_dict(ref):
  conn     = ref.get('conn')
  table    = ref.get('table')
  if not conn:
    return
  c = conn.cursor()
  insert   = ref.get('insert',{})
  fields   = insert.keys()
  fields_s = ",".join(fields)
  values   = list( map(lambda k: insert.get(k,''), fields) )
  quot     = list( map(lambda k: '?', fields) )
  quot_s   = ",".join(quot)
  q=''' INSERT OR IGNORE INTO %s (%s) VALUES (%s)''' % (table,fields_s,quot_s)

  try:
    c.execute(q,values)
  except sqlite3.IntegrityError, e:
    print(e)


def fill_from_files(db_file, root, root_id, proj, logfun):
  conn = sqlite3.connect(db_file)
  c = conn.cursor()

  if len(proj):
    pt = re.compile('^(%s)\.(?:(.*)\.|)(\w+)$' % proj)
    print('''("%s" project) Filling tables in db: 
              %s
          ''' % proj, db_file)
  else:
    pt = re.compile('^(\w+)\.(?:(.*)\.|)(\w+)$')
    print('''(all projects) Filling tables in db: 
              %s
          ''' % db_file)

  pt_bib   = re.compile('^(\w+)\.refs\.bib$')
  pt_dat_i = re.compile('^(.*)\.i$')

  f = []
  for (dirpath, dirnames, filenames) in os.walk(root):
    f.extend(filenames)
    break
  
  x = 0
  i = 0
  h_projs = []
  for file in f:
    i+=1
    fpath = os.path.join(root,file)
    m = pt.match(file)
    if m:
      proj_m = m.group(1)
      ext    = m.group(3)
      x+=1
      if ( not proj ) or ( proj_m == proj ):
        sec    = m.group(2)

        if ext == 'tex':
          if not sec: 
            sec = '_main_' 

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
        tags   = data.get('tags','')
        author = data.get('author','')

        insert_dict({
            'conn'     : conn,
            'table'    : 'projs',
            'insert' : { 
              'author'  : author,
              'file'    : file,
              'proj'    : proj_m,
              'root'    : root,
              'rootid'  : root_id,
              'sec'     : sec,
              'tags'    : tags,
             }
        })

  c.execute('''SELECT DISTINCT proj FROM projs''')
  rows = c.fetchall()
  for row in rows:
    proj = row[0]
    dir_pm = os.path.join(root,'perl','lib','projs',root_id,proj)
    if os.path.isdir(dir_pm):
      for (dirpath, dirnames, filenames) in os.walk(dir_pm):
        for f in filenames:
            file_pm = os.path.join(dir_pm,f)
            (head,tail) = os.path.split(file_pm)
            (root,ext) = os.path.splitext(tail)
            sec = '_pm.%s' % root 
            insert_dict({
                'conn'     : conn,
                'table'    : 'projs',
                'insert' : { 
                  'file'    : file_pm,
                  'proj'    : proj,
                  'root'    : root,
                  'rootid'  : root_id,
                  'sec'     : sec,
                 }
            })
        break

  conn.commit()
  conn.close()

