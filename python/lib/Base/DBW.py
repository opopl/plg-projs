
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

def sql_fetchlist(q, p=[], ref={}):
  r = sql_fetchall(q,p,ref)

  rows = r.get('rows',[])
  cols = r.get('cols',[])


  lst = []
  for rh in rows:
    for col in cols:
      v = rh.get(col)
      lst.append(v)

  return lst

def sql_fetchone_list(q, p=[], ref={}):
  r = sql_fetchone(q,p,ref)
  if not r:
    return 
  row  = r.get('row',{})
  cols = r.get('cols',[])
  lst = []
  for col in cols:
    v = row.get(col)
    lst.append(v)

  return lst

def sql_fetchval(q, p=[], ref={}):
  r    = sql_fetchone(q,p,ref)

  val = None
  if not r:
    return val

  row  = r.get('row',{})
  cols = r.get('cols',[])

  col = cols[0]
  val = row[col]
  return val

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

def _tb_exist(ref={}):
  db_file = ref.get('db_file','')
  table   = ref.get('table','')

  tb_list = _tb_list({ 'db_file' : db_file })
  return (table in tb_list) or False

def _tb_list(ref={}):
  db_file = ref.get('db_file','')

  q = f'''
    SELECT 
        name
    FROM 
        sqlite_master 
    WHERE 
        type = 'table' 
            AND 
        name NOT LIKE 'sqlite_%';
  '''

  tb_list = sql_fetchlist(q,[],{ 'db_file' : db_file })
  return tb_list

def _cols(ref={}):
  table   = ref.get('table','')
  db_file = ref.get('db_file','')

  q = f'''SELECT * FROM {table} LIMIT 1'''

  d = sql_fetchone(q,[],{ 'db_file' : db_file })
  cols = d.get('cols',[])

  return cols

def cond_where(ref={}):
  where = ref.get('where',{})

  where_keys    = list(where.keys())
  where_values  = [] 

  cond_a = []
  for k in where_keys:
    v = where.get(k,'')

    cond_k = ''
    if type(v) in [ int, str ]:
      where_values.append(v)
      cond_k = f' {k} = ? '

    elif type(v) in [ list ]:
      if len(v):
        where_values.extend(v)
  
        cond_k = ' OR '.join(list(map(lambda x: f' {k} = ? ', v)))
        cond_k = f'( {cond_k} )'

    if cond_k:
      cond_a.append(cond_k)

  values = []
  values.extend(where_values)

  cond  = ' AND '.join(cond_a)

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
      return { 'err' : 'no db_file' }

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
    return { 'err' : 'zero result' }

  cols = list(map(lambda x: x[0], c.description))

  rows = []
  for rw in rws:
    row = rw2dict(rw)
    rows.append(row)

  return { 'rows' : rows, 'cols' : cols }

def sql_do(ref={}):
  sql       = ref.get('sql','')
  sql_file  = ref.get('sql_file','')
  sql_files = ref.get('sql_files',[])

  conn     = ref.get('conn')
  db_file  = ref.get('db_file')
  db_close = ref.get('db_close')

  if len(sql_files):
    for sql_file in sql_files:
      sql_do({ 
        'sql_file' : sql_file,
        'db_file'  : db_file
      })
    return 1

  if sql_file and os.path.isfile(sql_file):
    with open(sql_file,'r') as f:
      sql = f.read()
  
      sql_do({ 
        'sql'     : sql,
        'db_file' : db_file
      })

    return 1

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

  return 1

def insert_update_dict(ref={}):
  db_file  = ref.get('db_file')
  db_close = ref.get('db_close')
  conn     = ref.get('conn')

  table  = ref.get('table')
  insert = ref.get('insert',{})

  on_list     = ref.get('on_list',[])
  on_w = {}
  if len(on_list):
    for on in on_list:
      if on in insert:
        on_val = insert.get(on,'')
        on_w[on] = on_val

  r = None
  if len(on_w):
    w_cond = ''
    w_cond_a = []
    w_values = []

    for on, on_val in on_w.items():
      w_cond_a.append(f' {on} = ? ')
      w_values.append(on_val)
    w_cond = ' and '.join(w_cond_a)

    r_db = {
      'db_file'  : db_file,
      'conn'     : conn,
      'db_close' : db_close
    }
    r = sql_fetchone(f'''select * from {table} where {w_cond}''',w_values,r_db)

  if not r:
     d = {
        'db_file' : db_file,
        'table'   : table,
        'insert'  : insert,
     }
     insert_dict(d)

  else:
     for on in on_list:
       del insert[on]

     d = {
        'db_file' : db_file,
        'table'   : table,
        'update'  : insert,
        'where'   : on_w
     }
     update_dict(d)

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
