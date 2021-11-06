
import re
import os
import sqlite3
import sqlparse
import sys

import Base.Util as util
import Base.String as string

import Base.Rgx as rgx

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

def sql_fetchone(q, p = [], ref = {}):
  conn     = ref.get('conn')
  db_file  = ref.get('db_file')
  db_close = ref.get('db_close')

  if not conn:
    if db_file:
      conn = sqlite3.connect(db_file)
      db_close = 1
    else:
      return

  where = ref.get('where',{})

  r      = cond_where({ 'where' : where })
  cond   = r.get('cond')
  values = r.get('values')

  if cond:
    q += ' WHERE ' + cond
    p.extend(values)

  conn_cfg(conn)

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
        type IN ( 'table' , 'view' )
            AND 
        name NOT LIKE 'sqlite_%'
    UNION ALL
    SELECT
        name
    FROM
        sqlite_temp_master
    WHERE
        type IN ('table','view')
    ORDER BY 1
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

def cond_orderby(ref={}):
  orderby = ref.get('orderby',{})

  if not len(orderby):
    return ''

  cond = ' ORDER BY '
  cond_a = []

  for key, mode in orderby.items():
    cond_a.append(f'{key} {mode.upper()}')

  cond += ','.join(cond_a)

  return cond

def cond_where(ref={}):
  where = ref.get('where',{})

  where_keys    = list(where.keys())
  where_values  = [] 

  cond_a = []
  for k in where_keys:
    v = where.get(k,'')

    if type(v) in [dict]:
      if k in ['@like']:
        like = v
        for y,z in like.items():
          cond_a.append(f' {y} LIKE "{z}" ')

      if k in ['@regexp']:
        regexp = v
        for key,pat in regexp.items():
          if pat:
            cond_a.append(f' RGX("{pat}",{key}) IS NOT NULL ')
      
      continue

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

def select(ref={}):
  db_file  = ref.get('db_file')

  table    = ref.get('table')
  where    = ref.get('where',{})
  select_a = ref.get('select',[])

  output   = ref.get('output','all')

  orderby  = ref.get('orderby',{})
  limit    = ref.get('limit')

  cond = ref.get('cond','')
  p    = ref.get('p',[])

  r_w      = cond_where({ 'where' : where })
  cond_w   = r_w.get('cond','') or ''
  values_w = r_w.get('values',[])

  if cond_w:
    if cond:
      cond = ' AND '.join( list(map(lambda x: f'( {x} )', [ cond, cond_w ] )) )
    else:
      cond = cond_w

  select_s = '*'
  if type(select_a) in [str]:
    select_a = [select_a]

  if len(select_a):
    select_s = ','.join(select_a) 

  q = f'SELECT {select_s} FROM {table}'
  if cond:
    q += f' WHERE ( {cond} )'
    p.extend(values_w)

  q += cond_orderby({ 'orderby' : orderby })
  if not limit in [None]:
    q += f' LIMIT {limit}'

  r_all = sql_fetchall(q,p,{ 'db_file' : db_file })

  rows_all = r_all.get('rows',[])
  cols     = r_all.get('cols',[])

  result = r_all
  if output == 'list':
    lst = []
    for rw in rows_all:
      for col in cols:
        lst.append(rw.get(col))
    result = lst

  elif output == 'first_row':
    rw = rows_all[0] if len(rows_all) else {}
    result = rw 

  return result

def conn_cfg(conn):
  conn.row_factory = sqlite3.Row
  conn.create_function("REGEXP", 2, rgx.rgx_match)
  conn.create_function("RGX", 2, rgx.rgx_match)
  conn.create_function("RGX_SUB", 3, rgx.rgx_sub)

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

  conn_cfg(conn)

  c = conn.cursor()

  try:
     c.execute(q,p)
  except sqlite3.OperationalError as e:
     print(e)
  except Exception as err:
     print('Query Failed: %s\nError: %s' % (q, str(err)))
  except:
     print("Errors ", sys.exc_info()[0], " for sqlite query: " + q )

  rws = c.fetchall()
  lastrowid = c.lastrowid
    
  if not rws:
    return { 'err' : 'zero result' }

  cols = list(map(lambda x: x[0], c.description))

  cfg_row = ref.get('row',{})
  as_list = cfg_row.get('list',0)

  rows = []
  rows_a = []
  for rw in rws:
    row = rw2dict(rw)
    row_a = util.dict2list(row,cols)
    rows.append(row)
    rows_a.append(row_a)

  if db_close:
    conn.commit()
    conn.close()

  return { 
    'rows'      : rows,
    'count'     : len(rows),
    'rows_a'    : rows_a,
    'cols'      : cols,
    'lastrowid' : lastrowid,
  }

def base2info(ref={}):
  # initial ('base') table
  tbase = ref.get('tbase') or ''

  # where condition for 'base' table
  bwhere = ref.get('bwhere') or {}

  # database file
  db_file = ref.get('db_file') or ''

  # 'join' column, i.e. foreign key field
  #   which 'joins' 'base' and 'info' tables
  jcol  = ref.get('jcol') or ''

  # 'base' => 'info' columns mapping
  b2i  = ref.get('b2i') or {}

  # columns in 'base' table which have to 
  #   be expanded into 'info' table
  bcols  = ref.get('bcols') or []

  for bcol in bcols:
     icol = b2i.get(bcol,bcol)
     sql = _sql_ct_info(tbase=tbase,bcol=bcol,jcol=jcol,icol=icol)
     sql_do({ 
        'db_file' : db_file,
        'sql'     : sql,
     })

  scols = [ jcol ]
  scols.extend(bcols)

  cond = ' OR '.join(list(map(lambda x: f'LENGTH({x}) > 0',bcols)))

  r = select({ 
    'table'   : tbase,
    'db_file' : db_file,
    'select'  : scols,
    'cond'    : cond,
    'where'   : bwhere,
  })
  rows_base = r.get('rows',[])

  for rw in rows_base:
    jval  = rw.get(jcol) or ''
    for bcol in bcols:
      # 'info' column name (icol) in the relevent 'info' table (itb)
      icol = b2i.get(bcol,bcol)

      # 'info' table name
      itb = f'_info_{tbase}_{bcol}' 

      # comma-separated value
      bval = rw.get(bcol) or ''

      ivals = string.split_n_trim(bval,sep=',')

      for ival in ivals:
        ins = { jcol : jval, icol : ival }
        r = select({
          'db_file' : db_file,
          'table'   : itb,
          'where'   : ins,
        })
        rows = r.get('rows',[])
        if not len(rows):
          insert_dict({
            'db_file' : db_file,
            'table'   : itb,
            'insert'  : ins,
          })

  return 1

def sql_do(ref={}):
  sql       = ref.get('sql','')
  sql_file  = ref.get('sql_file','')
  sql_files = ref.get('sql_files',[])

  p         = ref.get('p',[])

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

  conn_cfg(conn)
  c = conn.cursor()

  for q in sqlparse.split(sql):
    try:
        c.execute(q,p)
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
    q = f'''SELECT * FROM {table} WHERE {w_cond}'''
    r = sql_fetchone(q,w_values,r_db)
  
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

  return 1

def delete(ref={}):
  where = ref.get('where',{})

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

  r      = cond_where({ 'where' : where })
  cond   = r.get('cond')
  values = r.get('values')

  p = []
  q = f'''DELETE FROM {table}'''

  if cond:
    q += ' WHERE ' + cond
    p.extend(values)

  try:
    c.execute(q,values)
  except sqlite3.IntegrityError as e:
    raise Exception(f'[ERROR] SQlite error, query: {q}, params: {values}')    
    print(e)

  if db_close:
    conn.commit()
    conn.close()

  return 1


def _sql_ct_info(
     # 'base' table
     tbase='',
     # join column
     jcol='',
     # 'base' column
     bcol='', 
     # 'info' column
     icol=''
  ):

  if not icol:
    icol = bcol

  q = f'''
    CREATE TABLE IF NOT EXISTS _info_{tbase}_{bcol} (
        {jcol} TEXT NOT NULL,
        {icol} TEXT, 
        FOREIGN KEY({jcol}) REFERENCES {tbase}({jcol})
            ON DELETE CASCADE
            ON UPDATE CASCADE
    );
  '''

  return q

def insert_dict(ref={}):
  conn     = ref.get('conn')
  table    = ref.get('table')

  db_file   = ref.get('db_file')
  db_close  = ref.get('db_close')

  insert     = ref.get('insert',{})
  sql_insert = ref.get('sql_insert') or 'INSERT OR REPLACE'

  fields   = list(insert.keys())

  if ( len(fields) == 0 ) or not table:
    return 

  if not conn:
    if db_file:
      conn = sqlite3.connect(db_file)
      db_close = 1
    else:
      return

  conn_cfg(conn)
  c = conn.cursor()

  fields_s = ",".join(fields)
  values   = list( map(lambda k: insert.get(k,''), fields) )
  quot     = list( map(lambda k: '?', fields) )
  quot_s   = ",".join(quot)

  q = f'''{sql_insert} INTO {table} ({fields_s}) VALUES ({quot_s})'''

  try:
    c.execute(q,values)
  except sqlite3.IntegrityError as e:
    raise Exception(f'[ERROR] SQlite error, query: {q}, params: {values}')    
    print(e)

  if db_close:
    conn.commit()
    conn.close()

  return 1

def sql_file_exec(db_file, sql_file):
  ok = 1
  if not (os.path.isfile(db_file) and os.path.isfile(sql_file)):
    return

  conn = sqlite3.connect(db_file)
  c = conn.cursor()
  
  sql = open(sql_file, 'r').read()
  for q in sqlparse.split(sql):
    try:
      c.execute(q)
      ok = 0
    except sqlite3.OperationalError as e:
      print(e)
    except:
      print("Errors ", sys.exc_info()[0], " for sqlite query: " + q )
  
  conn.commit()
  conn.close()

  return ok
