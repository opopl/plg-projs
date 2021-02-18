
# ----------------------------
import os,sys,re
import cyrtranslit

import datetime

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const
# ----------------------------
from bs4 import BeautifulSoup, Comment

from Base.Scraper.Author import Author

from Base.Core import CoreClass

class RootPageParser(CoreClass):

  soup = None
  app  = None
  meta = None

  date_format = ''
  date_bare   = ''

  langs = util.qw('ukr rus')

  month_map_genitive = {
    'ukr' : {
      'січня'     : '01',
      'лютого'    : '02',
      'березня'   : '03',
      'квітня'    : '04',
      'травня'    : '05',
      'червня'    : '06',
      'липня'     : '07',
      'серпня'    : '08',
      'вересня'   : '09',
      'жовтня'    : '10',
      'листопада' : '11',
      'грудня'    : '12',
    },
    'rus' : {
      'января'   : '01',
      'февраля'  : '02',
      'марта'    : '03',
      'апреля'   : '04',
      'мая'      : '05',
      'июня'     : '06',
      'июля'     : '07',
      'августа'  : '08',
      'сентября' : '09',
      'октября'  : '10',
      'ноября'   : '11',
      'декабря'  : '12',
    }
  }

  def __init__(self,ref={}):
    super().__init__(ref)

    app = self.app

    self.auth_obj = Author({ 
      'page_parser' : self,
      'app'         : self.app
    })

    self.url = app.page.url
    self.og_url = util.get(self.app,'page.meta.og_url')
    if self.og_url:
      self.url = self.og_url

    self.url_struct = u = util.url_parse(self.url)
    self.url_path = path = u['path']

    parts = path.split('/')
    f = filter(lambda x: len(x) > 0, parts )
    self.url_parts = list(f)

  def clean(self,ref={}):
    return self

  def _txt_strip(self, txt='', opts = {}):
    txt_n = txt.split('\n')
    txt_n = list(map(lambda x: x.strip(),txt_n))
    txt_n = list(filter(lambda x: len(x) > 0,txt_n))
    txt = ''.join(txt_n)

    return txt



  def _txt_split(self, txt='', opts = {}):
    sep = opts.get('sep',const.comma)

    txt_n = txt.split('\n')
    txt_n = list(map(lambda x: x.strip(),txt_n))
    txt_n = list(filter(lambda x: len(x) > 0,txt_n))
    txt = ''.join(txt_n)

    if sep:
      txt = txt.split(sep)[0]

    sa = txt.split()

    return sa

  def _el_date_parts(self, el, opts = {}):

    sa = []

    sep = opts.get('sep',const.comma)

    txt = el.get_text()
    txt_n = txt.split('\n')
    txt_n = list(map(lambda x: x.strip(),txt_n))
    txt_n = list(filter(lambda x: len(x) > 0,txt_n))
    txt = ''.join(txt_n)
    txt = txt.split(sep)[0]

    sa = txt.split()

    return sa

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
    app = self.app

    sels = []
    sels.extend( app._cnf('PageParser.get_date.sels',[]) )
    sels.extend( app._site_data('PageParser.get_date.sels',[]) )

    tries = util.qw('ld_json meta html url')
    while len(tries):
      tri = tries.pop(0)

      sub_name = f'get_date_{tri}'
      app.log(f'[PageParser] call: {sub_name}')
      util.call(self, sub_name, [ ref ])

    return self

  def get_date_ld_json(self,ref={}):
    app = self.app
    page = app.page

    date = None

    ld_json = util.get(app.page,'ld_json',[])

    fmt = "%Y-%m-%d"
    sep = "T"

    for ld in ld_json:
      self.date_bare = ld.get('datePublished')
      if not self.date_bare:
        continue

      s = self.date_bare.split(sep)[0]
      d = datetime.datetime.strptime(s,fmt)
      date = d.strftime('%d_%m_%Y')
      if date:
        app.page.set({ 'date' : date })
        break

    return self

  def _sels(self,key=''):
    app = self.app

    if not key:
      return []

    sels = []
    sels.extend( app._cnf(f'PageParser.{key}.sels',[]) )
    sels.extend( app._site_data(f'PageParser.{key}.sels',[]) )

    return sels

  def get_date_url(self,ref={}):
    app = self.app

    return self

  def get_date_html(self,ref={}):
    app = self.app

    sels = self._sels('get_date_html')

    for sel in sels:
      date = self._date_from_sel(app.soup, sel)
      if date:
        app.page.set({ 'date' : date })
        break

    return self

  def _date_dmy(self,day,month,year):

    fmt = '%d_%m_%Y'
    date = '_'.join([day,month,year])
    dt = datetime.datetime.strptime(date,fmt)
    date = dt.strftime(fmt)

    return date

  def _date_from_bare(self,sel = {}):
    date = None

    fmt  = sel.get('fmt',"%Y-%m-%d")
    sep  = sel.get('split',"T")

    if not self.date_bare:
      return 

    try:
      d = datetime.datetime.strptime(self.date_bare,fmt)
      date = d.strftime('%d_%m_%Y')
    except:
      pass

    return date

  def _sel_date(self, soup, sel={}):
    date = self._date_from_sel(soup,sel)
    return date

  def _date_from_sel(self, soup, sel={}):
    date = None

    find = sel.get('find','')
    get  = sel.get('get','')
    fmt  = sel.get('fmt',"%Y-%m-%d")
    sep  = sel.get('split',"T")

    if not find:
      return 

    c = soup.select_one(find)
    if not c:
      return

    if get:
      if get == 'attr':
        attr = sel.get('attr','')
        if c.has_attr(attr):
          self.date_bare = c[attr]

      if get == 'text':
        txt = c.get_text()
        txt = self._txt_strip(txt)
        self.date_bare = txt

    if self.date_bare:
      s = self.date_bare.split(sep)[0]
      self.date_bare = s
      date = self._date_from_bare(sel)

    return date

  def get_date_meta(self,ref={}):
    app = self.app
    page = app.page

    rid = page.rid
      
    if not self.meta:
      self.import_meta()

    date = None

    sels = []
    sels.extend( app._cnf('PageParser.get_date_meta.sels',[]) )
    sels.extend( app._site_data('PageParser.get_date_html.sels',[]) )

    for sel in sels:
      date = self._date_from_sel(self.meta, sel)
      if date:
        self.app.page.set({ 'date' : date })
        break

    return self

  def get_author_ld_json(self,ref={}):
    app = self.app
    page = app.page

    d_parse = {}

    return self

  def get_author_meta(self,ref={}):
    app = self.app
    page = app.page

    rid = page.rid
    site = page.site
      
    if not self.meta:
      self.import_meta()

    d_parse = {}

    sels = []
    sels.extend( app._cnf('PageParser.get_author_meta.sels',[]) )
    sels.extend( app._site_data('PageParser.get_author_meta.sels',[]) )

    for itm in sels:
      d_parse = {}

      for k in util.qw('str url'):
        sel = itm.get(k)

        find = sel.get('find','')
        get  = sel.get('get','')

        if not find:
          continue

        c = self.meta.select_one(find)
        if c:
          if get == 'attr':
            attr = sel.get('attr','')
            if c.has_attr(attr):
              v = c[attr]
              d_parse.update({ k : v })

      auth_bare = util.get(d_parse,'str')
      if auth_bare:
        print(f'[PageParser] found author name: {auth_bare}')
        break

    self.auth_obj.parse(d_parse)

    return self

  def get_author(self,ref={}):
    app = self.app

    tries = util.qw('ld_json meta html')
    while len(tries):
      tri = tries.pop(0)

      if tri == 'ld_json':
        self.get_author_ld_json(ref)

      if tri == 'meta':
        self.get_author_meta(ref)

      if tri == 'html':
        self.get_author_html(ref)

    #if util.get(app, 'page.author_id'):
      #break

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
        d    = auth_sel.get(k)

        find = d.get('find','')
        get  = d.get('get','')
        attr = d.get('attr','')

        if not find:
          continue

        els = self.soup.select(find)
  
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

