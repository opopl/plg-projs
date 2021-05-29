# ----------------------------
import os,sys
import re
import cyrtranslit

import Base.DBW as dbw
import Base.Util as util
import Base.Const as const
import Base.String as string
# ----------------------------

from Base.Core import CoreClass

class Author(CoreClass):
  first_name        = None
  last_name         = None

  # SitePage instance
  page_parser = None

  # app instance
  app = None

  def _str_is_name_first(self,name=''):
    app = self.app
    lst = app.lists['names_first']

    ok = name in app._list('names_first',[])
    return ok

  def parse(self,ref={}):
    page_parser = self.page_parser
    app         = self.app

    auth_bare = ref.get('name','')
    auth_url  = ref.get('url','')

    if not auth_bare:
      return self

    if auth_url:
      auth_url  = util.url2base(app.page.baseurl, auth_url)
      app.log(f'[PageParser] found author url: {auth_url}')

    app.log(f'[PageParser] found author bare: {auth_bare}')

    auth_bare = re.sub(r'[,]*', r'', auth_bare)

    author_id = app.page.get('author_id','')
    auth_ids  = string.split_n_trim(author_id, ',')

    auth_list = []

    first_name = ''
    last_name  = ''
    remainder  = ''

    invert = False

    aa     = auth_bare.split(' ')
    i = 0
    while i < len(aa):
      aa[i] = aa[i].lower().capitalize()
      i+=1

    auth_bare = ' '.join(aa)
      
    first  = aa.pop(0)
    tail   = ' '.join(aa)

    invert = self._str_is_name_first(first)

    auth_id_bare = f'{first}_{tail}'
    if invert:
      auth_id_bare = f'{tail}_{first}'

    auth_id = cyrtranslit.to_latin(auth_id_bare,'ru')
    auth_id = re.sub(r'\s', r'_', auth_id)
    auth_id = re.sub(r'[\W]*', r'', auth_id)
    auth_id = auth_id.lower()

    #import pdb; pdb.set_trace()

    auth_name = auth_bare
    if invert:
      auth_name = f'{tail}, {first}'

    auth_db = app._db_get_auth({ 'auth_id' : auth_id })

    auth_update = app._act('auth_update')
    if not auth_db:
      auth_update = True
    else:
      if not auth_update:
        auth_name = auth_db.get('name')
        if not auth_url:
          auth_url = auth_db.get('url')

    app.log(f'[PageParser] author name: {auth_name}')

    auth_ids.append(auth_id)

    auth = {
      'id'   : auth_id,
      'name' : auth_name,
      'url'  : auth_url,
      'bare' : auth_bare,
    }
    auth_list.append(auth)

    if auth_update:
      d = {
        'db_file' : app.dbfile.pages,
        'table'   : 'authors',
        'insert'  : auth,
      }
      dbw.insert_dict(d)

    auth_ids = util.uniq(auth_ids)

    author_id = ','.join(auth_ids)
    if author_id:
      app.page.set({ 'author_id' : author_id })
      app.log(f'[Author] (list of authors) author_id = {author_id}')

    return self
