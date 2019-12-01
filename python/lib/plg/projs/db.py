
import sqlite3
import re
import os
import sqlparse,sys

#import pprint
#pp = pprint.PrettyPrinter(indent=4)

p = { 'texfile' : re.compile('^(\w+)\.(?:(.*)\.|)tex'), 
    'tags'      : re.compile('^\s*%%tags (.*)$'),
    'author'    : re.compile('^\s*%%author (.*)$')
   }

def create_tables(db_file, sql_file):
  conn = sqlite3.connect(db_file)
  c = conn.cursor()
  
  sql = open(sql_file, 'r').read()
  for q in sqlparse.split(sql):
    try:
        c.execute(q)
    except e:
        print("Errors ",sys.exc_info()[0]," for sqlite query: " + q )
  
  conn.commit()
  conn.close()

def drop_tables(db_file):
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
        data['tags']=m.group(1)
      m = p['author'].match(line)
      if m:
        data['author']=m.group(1)
  return data

def cleanup(db_file,root,proj):
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

def fill_from_files(db_file,root,rootid,proj_select,logfun):
  conn = sqlite3.connect(db_file)
  c = conn.cursor()

  f = []
  for (dirpath, dirnames, filenames) in os.walk(root):
    f.extend(filenames)
    break
  
  x = 0
  h_projs = []
  for file in f:
    fpath = os.path.join(root,file)
    m = p['texfile'].match(file)
    if m:
      x+=1
      proj = m.group(1)
      if ( not proj_select ) or ( proj == proj_select ):
        sec = m.group(2)
        if not sec: 
          sec = '_main_' 
        data   = get_data(fpath)
        tags   = data.get('tags','')
        author = data.get('author','')
        v_projs = [proj,sec,file,root,rootid,tags,author]
        q='''INSERT OR IGNORE INTO projs (proj,sec,file,root,rootid,tags,author) VALUES (?,?,?,?,?,?,?)'''
        try:
          c.execute(q,v_projs)
        except sqlite3.IntegrityError, e:
          logfun(e)
  conn.commit()
  conn.close()

