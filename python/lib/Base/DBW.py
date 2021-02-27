
import re
import os
import sqlite3
import sqlparse
import sys


def update_dict(ref):
  conn     = ref.get('conn')
  table    = ref.get('table')

  db_file   = ref.get('db_file')
  db_close  = ref.get('db_close')

  if not conn:
    if db_file:
      conn = sqlite3.connect(db_file)
      db_close = 1
    else:
      return

  c = conn.cursor()

  where     = ref.get('where',{})
  update    = ref.get('update',{})

  update_keys   = update.keys()
  update_values = list( map(lambda k: update.get(k,''), update_keys) )

  where_keys    = where.keys()
  where_values  = list( map(lambda k: where.get(k,''), where_keys) )

  values = []
  values.extend(update_values)
  values.extend(where_values)

  set_s = ','.join(list( map(lambda k: ' %s = ?' % k , update_keys ) ))
  where_s = ' AND '.join(list( map(lambda k: ' %s = ?' % k , where_keys ) ))

  q=''' UPDATE %s SET %s WHERE %s''' % (table,set_s,where_s)
  try:
    c.execute(q,values)
  except sqlite3.IntegrityError as e:
    print(e)

  if db_close:
    conn.commit()
    conn.close()

def rw2dict(rw):
  d = {}
  for k in rw.keys():
    d[k] = rw[k]
  return d

def sql_fetchone(q, p=[], ref={}):
  conn     = ref.get('conn')
  db_file  = ref.get('db_file')
  db_close = ref.get('db_close')

  if not conn:
    if db_file:
      conn = sqlite3.connect(db_file)
      db_close = 1
    else:
      return

  conn.row_factory = sqlite3.Row
  c = conn.cursor()

  try:
     c.execute(q,p)
  except sqlite3.OperationalError as e:
     print(e)
  except:
     print("Errors ", sys.exc_info()[0], " for sqlite query: " + q )
  rw = c.fetchone()

  if not rw:
    return

  row = rw2dict(rw)

  cols = list(row.keys()) 
  cols.sort()

  return { 'row' : row, 'cols' : cols }

def _cols(ref={}):
  table   = ref.get('table','')
  db_file = ref.get('db_file','')

  q = f'''SELECT * FROM {table} LIMIT 1'''

  d = sql_fetchone(q,[],{ 'db_file' : db_file })
  cols = d.get('cols',[])

  return cols

def cond_where(ref={}):
  where = ref.get('where',{})

  where_keys    = where.keys()
  where_values  = list( map(lambda k: where.get(k,''), where_keys) )

  values = []
  values.extend(where_values)

  cond  = ' AND '.join(list( map(lambda k: ' %s = ?' % k , where_keys ) ))

  r = { 'cond' : cond, 'values' : values }

  return r

def sql_fetchall(q, p=[], ref={}):
  conn     = ref.get('conn')
  db_close = ref.get('db_close')

  db_file  = ref.get('db_file')

  where = ref.get('where',{})

  r      = cond_where({ 'where' : where })
  cond   = r.get('cond')
  values = r.get('values')

  if cond:
    q += ' WHERE ' + cond
    p.extend(values)

  if not conn:
    if db_file:
      conn = sqlite3.connect(db_file)
      db_close = 1
    else:
      return

  conn.row_factory = sqlite3.Row
  c = conn.cursor()

  try:
     c.execute(q,p)
  except sqlite3.OperationalError as e:
     print(e)
  except:
     print("Errors ", sys.exc_info()[0], " for sqlite query: " + q )

  rws = c.fetchall()
  if not rws:
    return 

  cols = list(map(lambda x: x[0], c.description))

  rows = []
  for rw in rws:
    row = rw2dict(rw)
    rows.append(row)

  return { 'rows' : rows, 'cols' : cols }

def sql_do(ref={}):
  sql      = ref.get('sql','')

  conn     = ref.get('conn')
  db_file  = ref.get('db_file')
  db_close = ref.get('db_close')

  if not conn:
    if db_file:
      conn = sqlite3.connect(db_file)
      db_close = 1
    else:
      return

  c = conn.cursor()

  for q in sqlparse.split(sql):
    try:
        c.execute(q)
    except sqlite3.OperationalError as e:
        print(e)
    except:
        print("Errors ", sys.exc_info()[0], " for sqlite query: " + q )

  if db_close:
    conn.commit()
    conn.close()

def insert_dict(ref={}):
  conn     = ref.get('conn')
  table    = ref.get('table')

  db_file   = ref.get('db_file')
  db_close  = ref.get('db_close')

  insert   = ref.get('insert',{})
  fields   = insert.keys()

  if ( len(fields) == 0 ) or not table:
    return 

  if not conn:
    if db_file:
      conn = sqlite3.connect(db_file)
      db_close = 1
    else:
      return

  c = conn.cursor()

  fields_s = ",".join(fields)
  values   = list( map(lambda k: insert.get(k,''), fields) )
  quot     = list( map(lambda k: '?', fields) )
  quot_s   = ",".join(quot)
  q=''' INSERT OR REPLACE INTO %s (%s) VALUES (%s)''' % (table,fields_s,quot_s)

  try:
    c.execute(q,values)
  except sqlite3.IntegrityError as e:
    raise Exception(f'[ERROR] SQlite error, query: {q}, params: {values}')    
    print(e)

  if db_close:
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
