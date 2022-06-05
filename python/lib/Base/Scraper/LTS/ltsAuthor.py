
import Base.DBW as dbw

import Base.Util as util
import Base.String as string
import Base.Const as const

import os,re,sys
from pathlib import Path

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Rgx as rgx

class ltsAuthor:

  def author_db_pages_util(self, ref = {}):

    db_file = self.db_file_pages
    q = f'''SELECT
                auth_id, rids
            FROM
                auth_stats
            WHERE
                auth_id NOT IN (SELECT id FROM authors)'''
    p = []

    r = dbw.sql_fetchall(q,p,{ 'db_file' : db_file })
    rows = r.get('rows',[])
    for rw in rows:
      rids_s = rw.get('rids')
      rids = rids_s.split(',')
      for rid in rids:
        r = dbw.select({
          'db_file'  : db_file,
          'table'  : 'pages',
          'where'  : { 'rid'  : rid },
          'select' : [ 'url', 'author_id' ],
          'output' : 'first_row',
        })
        if not len(r):
          continue

        url = r.get('url','')
        import pdb; pdb.set_trace()

    return self

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

  def author_dat_update(self, ref = {}):

    return self

  def author_import_dat2db(self, ref = {}):
    names_first = util.readarr(self.dat_files['names'])

    # disable fk
    fk = ref.get('fk',0)

    fb_authors = util.readdict(self.dat_files['fb_authors'])
    fb_groups  = util.readdict(self.dat_files['fb_groups'])

    authors_file = self.dat_files['authors']

    home = os.environ.get('HOME')
    #db_file = os.path.join(home,'tmp','h.db')

    with open(authors_file,'r',encoding='utf8') as f:
      self.lines = f.readlines()
      while len(self.lines):
        self.line = self.lines.pop(0).strip('\n')
        if re.match(r'^#',self.line) or (len(self.line) == 0):
          continue

        m = rgx.match('author.dict',self.line)
        if m:
          author_id    = m.group('author_id')

          # facebook ids corresponding to single author_id
          fb_ids = []

          # facebook group ids corresponding to single author_id
          fb_group_ids = []

          # incoming author string
          author_bare  = m.group('author_bare')

          # plain author name
          author_plain = author_bare

          # inverted if needed
          author_name  = author_bare

          m = rgx.match('author.bare.inverted',author_bare)
          if m:
            last_name  = m.group('last_name').strip()
            first_name = m.group('first_name').strip()
            info       = m.group('info')
            author_plain = f'{first_name} {last_name}'
            if info:
              author_plain = f'{author_plain} ({info})'

            if not first_name in names_first:
              author_name = author_plain

          for fb_group_id, a_id in fb_groups.items():
            if f'fb_group.{a_id}' == author_id:
              fb_group_ids.append(fb_group_id)

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
            'on_list' : [ 'id' ],
            'fk'      : fk,
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
              'on_list' : [ 'id', 'fb_id' ],
              'fk'      : fk,
            }
            dbw.insert_update_dict(d)

          for fb_group_id in fb_group_ids:
            d_auth_detail = {
              'id'     : author_id,
              'fb_url' : f'https://www.facebook.com/groups/{fb_group_id}',
              'fb_group_id'  : fb_group_id,
            }
            d = {
              'db_file' : self.db_file_pages,
              'table'   : 'auth_details',
              'insert'  : d_auth_detail,
              'on_list' : [ 'id' ],
              'fk'      : fk,
            }
            dbw.insert_update_dict(d)

    r_db = { 'db_file' : self.db_file_pages }

    cnt = {}
    for t in util.qw('authors auth_details'):
      cnt[t] = dbw.sql_fetchval(f'select count(*) from {t}',[],r_db)

    print(f'Count(authors):      {cnt["authors"]}')
    print(f'Count(auth_details): {cnt["auth_details"]}')

    return self

  # see also: author_move
  def author_move_dat(self, ref = {}):
    old       = ref.get('old','')
    new       = ref.get('new','')
    if not old and new:
      return self

    for dat_name, dat_path in self.dat_files.items():
      m = re.search('authors$',dat_name)
      if not m:
        continue

      dict = util.readdict(dat_path)
      if dat_name == 'authors':
        if not old in dict:
          continue

        author_name = dict[old]
        del dict[old]
        dict.update({ new : author_name })

      else:
        for wid, author_id in dict.items():
          if author_id == old:
            dict.update({ wid : new })

      util.writedict(dat_path, dict)

    return self

  def author_move_db_projs(self, ref = {}):
    old       = ref.get('old','')
    new       = ref.get('new','')
    if not old and new:
      return self

    db_file = self.db_file_projs

    tbase = '_info_projs_author_id'
    key = 'author_id'
    q = f'''PRAGMA foreign_keys = OFF;
            UPDATE {tbase}
            SET {key} = '{new}'
            WHERE {key} = '{old}';
            PRAGMA foreign_keys = ON;
        '''

    dbw.sql_do({
      'sql'     : q,
      'db_file' : db_file
    })

    q = f'''SELECT sec FROM projs WHERE file IN ( SELECT file FROM {tbase} WHERE {key} = ? )'''
    secs = dbw.sql_fetchlist(q, [ new ], { 'db_file' : db_file })
    for sec in secs:
      acts = [
        [ 'sec_author_rm', [ { 'sec' : sec, 'author_id' : old } ] ],
        [ 'sec_author_add', [ { 'sec' : sec, 'author_id' : new } ] ],
      ]

      util.call(self,acts)

    return self

  def author_move_db_pages_main(self, ref = {}):
    old       = ref.get('old','')
    new       = ref.get('new','')
    if not old and new:
      return self

    db_file = self.db_file_pages
    table = 'pages'

    q = f'''SELECT rid, author_id FROM {table}'''
    r = dbw.sql_fetchall(q,[],{ 'db_file' : db_file })
    rows = r.get('rows',[])
    for rw in rows:
      rid       = rw.get('rid')
      author_id = rw.get('author_id') or ''
      if not author_id:
        continue

      ids = string.split_n_trim(author_id, sep = ',')
      if old in ids:
        author_id = string.ids_merge([ author_id, new ])
        author_id = string.ids_remove([ author_id ], [ old ])

        d = {
          'db_file' : db_file,
          'table'   : table,
          'insert'  : {
             'rid'       : rid,
             'author_id' : author_id,
          },
          'on_list' : [ 'rid' ]
        }

        dbw.insert_update_dict(d)

    return self

