
# ----------------------------
import os,sys,re
import cyrtranslit

import datetime

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
  meta = None

  def __init__(self,ref={}):
    super().__init__(ref)

    self.auth_obj = Author({ 
      'page_parser' : self,
      'app'         : self.app
    })

  def generate_ii(self,ref={}):
    app = self.app
    if app.page.title:
      tt = app.page.title
      tt = re.sub(r'\s', '_', tt)
      ttl = cyrtranslit.to_latin(tt,'ru').lower()
      ttl = re.sub(r'[\W\']+', '', ttl)
      app.page.ii = ttl

    return self

  def import_meta(self):
    app = self.app

    meta_txt = app._file_rid({ 'tipe' : 'meta', 'ext' : 'txt' })
    with open(meta_txt,'r') as f:
      meta_cnt = f.read()

    self.meta = BeautifulSoup(meta_cnt,'html5lib')

    return self

  def get_date(self,ref={}):

    self.get_date_meta(ref)

    return self

  def get_date_meta(self,ref={}):
    app = self.app
    page = app.page

    rid = page.rid
      
    if not self.meta:
      self.import_meta()

    c = self.meta.select_one('meta[itemprop="datePublished"]')

    if c:
      date_s = c['content']
      s = date_s.split('T')[0]
      f = "%Y-%m-%d"
      d = datetime.datetime.strptime(s,f)
      date = d.strftime('%d_%m_%Y')
      self.app.page.set({ 'date' : date })

    return self

  def get_author_meta(self,ref={}):
    app = self.app
    page = app.page

    rid = page.rid
      
    if not self.meta:
      self.import_meta()

    sels = [
      { 
        'str' :  'meta[name="author"]',
        'url' :  'meta[property="article:author"]',
      }
    ]

    d_parse = {}

    for itm in sels:
      for k, sel in itm.items():
        c = self.meta.select_one(sel)
        if c:
          v = c['content']
          d_parse.update({ k : v })

      auth_bare = util.get(d_parse,'str')
      if auth_bare:
        print(f'[PageParser] found author name: {auth_bare}')
        break

    self.auth_obj.parse(d_parse)

    return self

  def get_author(self,ref={}):
    app = self.app

    self.get_author_meta(ref)

    if not util.get(app, 'page.author_id'):
      self.get_author_html(ref)

    return self

  def get_author_html(self,ref={}):
    site = self.app.page.site

    sel = ref.get('sel','')

    auth_sel = util.get( self.app, [ 'sites', site, 'sel', 'author' ] )
    if not auth_sel:
      return self

    if type(auth_sel) is dict:
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

      self.auth_obj.parse(d_parse)

    return self

