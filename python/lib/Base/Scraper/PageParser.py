
# ----------------------------
import os,sys,re
import cyrtranslit

import Base.DBW as dbw
import Base.Util as util
import Base.Const as const
# ----------------------------
from bs4 import BeautifulSoup, Comment

from Base.Scraper.Author import Author

from Base.Core import CoreClass

class RootPageParser(CoreClass):

  soup        = None
  app         = None
  date_format = ''

  def generate_ii(self,ref={}):
    app = self.app
    if app.page.title:
      tt = app.page.title
      tt = re.sub(r'\s', '_', tt)
      ttl = cyrtranslit.to_latin(tt,'ru').lower()
      ttl = re.sub(r'[\W\']+', '', ttl)
      app.page.ii = ttl

    return self

  def get_date(self,ref={}):
    app = self.app
    page = app.page

    rid = page.rid

    meta_file = app._file_rid({ 'tipe' : 'meta', 'ext' : 'txt' })
    with open(meta_file,'r') as f:
      meta = f.read()
      
    bs = BeautifulSoup(meta,'html5lib')
    c = bs.select_one('meta[itemprop="datePublished"]')
    if c:
      date_s = c['content']
      pass
    import pdb; pdb.set_trace()

    return self

  def get_author(self,ref={}):
    site = self.app.page.site

    sel = ref.get('sel','')
    auth_sel = util.get( self.app, [ 'sites', site, 'sel', 'author' ] )
    if not auth_sel:
      return self

    if type(auth_sel) is dict:

      auth_obj = Author({ 
        'page_parser' : self,
        'app'         : self.app
      })

      d = {}

      d_parse = {}
      for k in util.qw('url name'):
        d  = auth_sel.get(k)
        css  = d.get('css')
        attr = d.get('attr')

        els = self.soup.select(css)
  
        for e in els:
          auth = None
    
          if k == 'url':
            if e.has_attr(attr):
              auth_url  = util.url_join(self.app.base_url, e[attr])
              print(f'[PageParser] found author url: {auth_url}')

              d_parse.update({ 'url' : auth_url })
          elif k == 'name':
            s = e.string
            auth_bare = util.strip(s)
            if auth_bare:
              print(f'[PageParser] found author name: {auth_bare}')

              d_parse.update({ 'str' : auth_bare })

      auth_obj.parse(d_parse)

    return self

