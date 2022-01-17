
import Base.DBW as dbw

import Base.Util as util
import Base.String as string
import Base.Const as const

class ltsAuthor:

  def author_move_db_pages(self, ref = {}):
    old       = ref.get('old','')
    new       = ref.get('new','')
    if not old and new:
      return self

    db_file = self.db_file_pages

    lst = [
        { 'table' : 'authors', 'key' : 'id' },
        { 'table' : 'auth_details', 'key' : 'id' },
        { 'table' : 'page_authors', 'key' : 'auth_id' },
        { 'table' : 'auth_stats', 'key' : 'auth_id' },
    ]
    do = 'move'
    if self._author_exist(id=new):
      do = 'merge'
      # authors          delete entry
      # auth_details     delete entry

      # auth_stats       merge list of rids, rank
      # page_authors     update

    for item in lst:
      table = item.get('table')
      key   = item.get('key')

###auth_move
      if do == 'move':
        q = f'''UPDATE {table} SET {key} = ? WHERE {key} = ? '''
        dbw.sql_do({
           'db_file' : db_file,
           'sql'     : q,
           'p'       : [ new, old ],
           'fk'      : 0
        })

###auth_move_merge
      elif do == 'merge':
        if table in util.qw('authors auth_details'):
           q = f''' DELETE FROM {table} WHERE {key} = ? '''
           dbw.sql_do({
             'db_file' : db_file,
             'sql'     : q,
             'p'       : [ old ],
             'fk'      : 0
           })

        elif table in util.qw('page_authors'):
          q = f'''UPDATE {table} SET {key} = ? WHERE {key} = ? '''
          dbw.sql_do({
             'db_file' : db_file,
             'sql'     : q,
             'p'       : [ new, old ],
             'fk'      : 0
          })

        elif table in util.qw('auth_stats'):
          rids = {}
          rank = {}
          jj = { 'old' : old, 'new' : new }
          for k, v in jj.items():
            q = f'SELECT rank, rids FROM {table} WHERE {key} = ?'
            p = [v]
            r = dbw.sql_fetchone(q,p,{ 'db_file' : db_file }) or {}
            row  = r.get('row',{})
            rank[k] = row.get('rank',0)
            rids[k] = row.get('rids','')

          rank['new'] = rank['old'] + rank['new']
          rids['new'] = string.ids_merge([ rids['new'], rids['old'] ])

          # delete old entry
          q = f''' DELETE FROM {table} WHERE {key} = ? '''
          dbw.sql_do({
            'db_file' : db_file,
            'sql'     : q,
            'p'       : [ old ],
            'fk'      : 0
          })

          # update new entry with merged rank and rids values
          d = {
            'db_file' : db_file,
            'table'   : table,
            'insert'  : {
               key    : new,
               'rank' : rank['new'],
               'rids' : rids['new']
            },
            'on_list' : [ key ]
          }

          dbw.insert_update_dict(d)

    return self

  def author_delete(self, ref = {}):
    author_id       = ref.get('author_id','')

    acts = [
        [ 'author_delete_db_pages', [ ref ] ],
        [ 'author_delete_db_projs', [ ref ] ],
        [ 'author_delete_dat', [ ref ] ],
    ]

    util.call(self,acts)

    return self

  def author_delete_dat(self, ref = {}):
    author_id       = ref.get('author_id','')

    return self

  def author_delete_db_projs(self, ref = {}):
    author_id = ref.get('author_id','')
    if not author_id:
      return self

    db_file = self.db_file_projs
    tbase = '_info_projs_author_id'
    key = 'author_id'

    q = f'''SELECT sec FROM projs WHERE file IN ( SELECT file FROM {tbase} WHERE {key} = ? )'''
    secs = dbw.sql_fetchlist(q, [ author_id ], { 'db_file' : db_file })
    for sec in secs:
      acts = [
        [ 'sec_author_rm', [ { 'sec' : sec, 'author_id' : author_id } ] ],
      ]

      util.call(self,acts)

    return self

  def author_delete_db_pages(self, ref = {}):
    author_id = ref.get('author_id','')
    if not author_id:
      return self

    db_file = self.db_file_pages

    lst = [
        { 'table' : 'authors', 'key' : 'id' },
        { 'table' : 'auth_details', 'key' : 'id' },
        { 'table' : 'page_authors', 'key' : 'auth_id' },
        { 'table' : 'auth_stats', 'key' : 'auth_id' },
    ]

    for item in lst:
      table = item.get('table')
      key   = item.get('key')

      q = f'''PRAGMA foreign_keys = OFF;
              DELETE FROM
                  {table}
              WHERE
                  {key} = '{author_id}';
              PRAGMA foreign_keys = ON;
          '''

      dbw.sql_do({
        'sql'     : q,
        'db_file' : db_file
      })

    return self

  def author_move(self, ref = {}):
    old       = ref.get('old','')
    new       = ref.get('new','')

    ok = old
    ok = ok and new and ( old != new )
    ok = ok and self._author_exist(id=old)
    if not ok:
      return self

    acts = [
      [ 'author_move_db_pages_main', [ ref ] ],
      [ 'author_move_db_pages', [ ref ] ],
      [ 'author_move_db_projs', [ ref ] ],
      [ 'author_move_dat', [ ref ] ],
    ]

    util.call(self,acts)

    return self

  def _author_exist(self, id = ''):
    id = dbw.sql_fetchval('SELECT id FROM authors WHERE id = ?',[ id ],
      { 'db_file' : self.db_file_pages })
    return id

  def _author_id_remove(self, ids_in = [], ids_rm = []):
    return string.ids_remove(ids_in, ids_rm)

  def _author_id_merge(self,ids_in = []):
    return string.ids_merge(ids_in)

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

