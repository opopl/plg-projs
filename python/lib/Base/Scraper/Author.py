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

  def _tail_nice(self,**args):
    tail = args.get('tail','')

    aa   = tail.split(' ')

    i = 0
    while i < len(aa):
      s = aa[i]
      s = s.strip(' ')
      s = re.sub(r'^\W+$', r'', s)
      s = re.sub(r'^\W', r'_', s)
      s = s.lower().capitalize()

      aa[i] = s
      i+=1
    tail = ' '.join(aa)
    tail = tail.strip(' ')

    return tail

  def _str_is_name_first(self,name=''):
    app = self.app
    lst = app.lists['names_first']

    name = name.lower().capitalize()

    ok = name in app._list('names_first',[])
    return ok

  def _bare2auth(self,ref={}):
    ''' called by:
          Author.parse()
    '''
    auth_bare   = ref.get('auth_bare','')
    auth_url    = ref.get('auth_url','')

    auth_update = ref.get('auth_update',0)

    app = self.app

    first_name = ''
    last_name  = ''
    remainder  = ''

    invert = False

    aa     = auth_bare.split(' ')
    first  = aa.pop(0)

    tail   = ' '.join(aa)
    tail = self._tail_nice(tail=tail)
    auth_plain = f'{first} {tail}'

    invert = self._str_is_name_first(first)

    if tail:
      auth_id_bare = f'{first}_{tail}'
    else:
      auth_id_bare = f'{first}'

    if invert:
      first = first.lower().capitalize()

      auth_id_bare = f'{tail}_{first}'

    auth_id = cyrtranslit.to_latin(auth_id_bare,'ru')
    auth_id = re.sub(r'\s', r'_', auth_id)
    auth_id = re.sub(r'[\W]*', r'', auth_id)
    auth_id = auth_id.lower()

    auth_name = auth_bare
    if invert:
      auth_name = f'{tail}, {first}'

    auth_db = app._db_get_auth({ 'auth_id' : auth_id })
    #import pdb; pdb.set_trace()

    auth_update = app._act('auth_update')
    if not auth_db:
      auth_update = True
    else:
      if not auth_update:
        auth_name = auth_db.get('name')
        if not auth_url:
          auth_url = auth_db.get('url')

    app.log(f'[PageParser] author name: {auth_name}')

    auth = {
      'id'    : auth_id,
      'name'  : auth_name,
      'url'   : auth_url,
      'plain' : auth_plain,
    }

    return [ auth, auth_update ]

  def parse(self,ref={}):
    '''
    '''
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

    [ auth, auth_update ] = self._bare2auth({ 
      'auth_bare' : auth_bare,
      'auth_url'  : auth_url,
    })
    auth_id = auth.get('id','')

    if auth_id:
      auth_ids.append(auth_id)

    auth_list = []

    auth_list.append(auth)

    if auth_update:
      d = {
        'db_file' : app.dbfile.pages,
        'table'   : 'authors',
        'insert'  : auth,
        'fk' : 0,
      }
      dbw.insert_dict(d)

    auth_ids = util.uniq(auth_ids)

    author_id = ','.join(auth_ids)
    if author_id:
      app.page.set({ 'author_id' : author_id })
      app.log(f'[Author] (list of authors) author_id = {author_id}')

    return self
