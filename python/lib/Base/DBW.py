
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

  c.execute(q,values)

  try:
    c.execute(q,values)
  except sqlite3.IntegrityError as e:
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