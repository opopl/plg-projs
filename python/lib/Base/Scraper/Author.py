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

  def _is_last_name(self,name=''):
    app         = self.app

    ok = False
    if name in util.get(app,'names.last',[]):
      ok = True
    return ok

  def _is_name(self,name=''):
    app         = self.app

    ok = True
    if name in app._list('names_exclude_bare',[]):
      ok = False
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

    aa = auth_bare.split(' ')
    namlen = len(aa)

    auth_id = auth_bare

    if namlen >= 2:
      first_name = aa.pop(0)
      last_name  = aa.pop(0)
      remainder  = ' '.join(aa)

      if self._is_name(auth_bare):
        invert = True

      if namlen == 2:
        # last_name <=> first_name
        if self._is_last_name(first_name):
          invert = True

          ln = last_name
          last_name = first_name
          first_name = ln

      auth_id = f'{last_name}_{first_name}'
      if remainder:
        auth_id = f'{auth_id}_{remainder}'

    auth_id = cyrtranslit.to_latin(auth_id,'ru')
    auth_id = re.sub(r'\s', r'_', auth_id)
    auth_id = re.sub(r'[\W]*', r'', auth_id)
    auth_id = auth_id.lower()

    auth_name = auth_bare
    if invert:
      auth_name = f'{last_name}, {first_name}'

    auth_db = app._db_get_auth({ 'auth_id' : auth_id })

    auth_update = app._act('auth_update')
    if not auth_db:
      auth_update = True

    if auth_db:
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
