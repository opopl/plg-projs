
import sqlite3
import numpy as np

import sys,os
import getopt,argparse

def f_nz(x): 
  ok = 0
  if (x is not None ) and (len(x) > 0): 
    ok = 1
  return ok

def f_none(x): 
  ok = 0
  if (x is not None ): 
    ok = 1
  return ok

def f_str(x): 
  if x is None:
    return ''
  return str(x)

usage='''
This script will index tags within the "projs" sqlite database
'''
parser = argparse.ArgumentParser(usage=usage)

parser.add_argument("--db_file", help="db_file",default="")

args = parser.parse_args()

if len(sys.argv) == 1:
  parser.print_help()
  sys.exit()

db_file = args.db_file

if not db_file:
  print('db_file not provided!')
  sys.exit()

dbfile           = vim.eval('dbfile')

conn             = sqlite3.connect(dbfile)
conn.row_factory = sqlite3.Row
c                = conn.cursor()

try:
  print('indexing files...')
  q = 'SELECT file,tags FROM projs'
  c.execute(q)
  rows = c.fetchall()
  fid  = 1
  i = 0
  for row in rows:
    file = row['file']
    tags = row['tags'].split(',') 
    tags = list(filter(f_nz,tags))
    for tag in tags:
      fids_str = ''
      q = '''
        SELECT 
          fid 
        FROM 
          projs 
        WHERE 
          tags LIKE "_tg_,%" 
            OR
          tags LIKE "%,_tg_" 
            OR
          tags LIKE "%,_tg_,%" 
            OR
          tags = "_tg_"
        '''.replace('_tg_',tag)
      try:
        c.execute(q)
      except:
        print('error for query: ' + q)
      c.row_factory = lambda cursor, row: row[0]
      fids = c.fetchall()
      fids = filter(f_none,fids)
      fids = list(set(fids))
      fids.sort()
      try:
        fids = list(map(f_str,fids))
        fids_str = ",".join(fids)
        rank = len(fids)
        q = '''INSERT OR REPLACE INTO tags (tag,rank,fids) VALUES (?,?,?)'''
        c.execute(q,(tag,rank,fids_str))
      except:
        print('error for query: ' + q)
    q = '''UPDATE projs SET fid = ? WHERE file = ?'''
    try:
      c.execute(q,(fid, file))
    except:
      print('error for query: ' + q)
    fid+=1
    i+=1

  #index projects
  print('indexing projects...')
  q = 'SELECT DISTINCT proj FROM projs'
  c.row_factory = sqlite3.Row
  c.execute(q)
  rows = c.fetchall()
  pid  = 1
  i = 0
  for row in rows:
    proj = row['proj']
    q = '''UPDATE projs SET pid = ? WHERE proj = ?'''
    c.execute(q,( pid, proj ) )
    pid+=1
except TypeError as e:
  print(e)
except:
  print("Unexpected error:", sys.exc_info()[0])
  raise
finally:
  conn.commit()
  conn.close()
eof

