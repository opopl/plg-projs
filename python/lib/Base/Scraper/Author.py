# ----------------------------
import os,sys
import cyrtranslit

import Base.DBW as dbw
import Base.Util as util
import Base.Const as const
# ----------------------------

from Base.Core import CoreClass

class Author(CoreClass):
  first_name        = None
  last_name         = None

  # SitePage instance
  page_parser = None

  # app instance
  app = None

  def parse(self,ref={}):
    page_parser = self.page_parser
    app         = self.app

    auth_bare = ref.get('str','')
    auth_url  = ref.get('url','')

    if not auth_bare:
      return self

    auth_ids = []
    auth_list = []

    aa = auth_bare.split(' ')
    if len(aa) == 2:
      first_name = aa[0]
      last_name  = aa[1]

      auth_id = f'{last_name}_{first_name}'.lower()
      auth_id = cyrtranslit.to_latin(auth_id,'ru')

      auth_db = app._db_get_auth({ 'auth_id' : auth_id })
      if not auth_db:
        auth_name = f'{last_name}, {first_name}'
      else:
        auth_name = auth_db.get('name')
        if not auth_url:
          auth_url = auth_db.get('url')

      auth_ids.append(auth_id)

      if auth_url:
        u = util.url_parse(auth_url)
        if not u['netloc']:
           auth_url = util.url_join(app.page.url, auth_url)

      auth = {
        'id'   : auth_id,
        'name' : auth_name,
        'url'  : auth_url,
      }
      auth_list.append(auth)

      if not auth_db:
        d = {
          'db_file' : app.dbfile.pages,
          'table'   : 'authors',
          'insert'  : auth,
        }
        dbw.insert_dict(d)

    author_id = ','.join(auth_ids)
    if author_id:
      app.page.set({ 'author_id' : author_id })
      app.log(f'[Author] author_id = {author_id}')


    return self
