# ----------------------------
import os,sys
import cyrtranslit

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)

plg = os.environ.get('PLG')
add_libs([ os.path.join(plg,'projs','python','lib') ])
import Base.DBW as dbw
import Base.Util as util
import Base.Const as const
# ----------------------------

class Author:
  first_name        = None
  last_name         = None

  # SitePage instance
  spage = None

  # app instance
  app = None

  def __init__(self,args={}):
    for k, v in args.items():
      setattr(self, k, v)

  def parse(self,ref={}):
    spage = self.spage
    app   = self.app

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

      auth_db = spage.app._db_get_auth({ 'auth_id' : auth_id })
      if not auth_db:
        auth_name = f'{last_name}, {first_name}'
      else:
        auth_name = auth_db.get('name')
        if not auth_url:
          auth_url = auth_db.get('url')

      auth_ids.append(auth_id)

      auth = {
        'id'   : auth_id,
        'name' : auth_name,
        'url'  : auth_url,
      }
      auth_list.append(auth)

      if not auth_db:
        d = {
          'db_file' : spage.app.url_db,
          'table'   : 'authors',
          'insert'  : auth,
        }
        dbw.insert_dict(d)

    author_id = ','.join(auth_ids)
    if author_id:
      app.page.update({ 'author_id' : author_id })
    return self