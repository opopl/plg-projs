
# ----------------------------
import os,sys,re
import cyrtranslit

import datetime
import dateparser

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

  date_fmt = '%d_%m_%Y'

  langs = util.qw('uk ru')

  month_map_genitive = {
    'uk' : {
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
    'ru' : {
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

  def _month_by_gen(self, month_gen=''):

    month = None
    for lang in self.langs:
      month = self.month_map_genitive.get(lang,{}).get(month_gen,'')
      if month:
        break

    return month

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

    fmt  = sel.get('fmt',"%Y-%m-%d")
    sep  = sel.get('split',"T")

    if not self.date_bare:
      return 

    tries = util.qw('by_fmt dateparser')

    date = None
    dt = None

    for tri in tries:
      if tri == 'by_fmt':
        try:
          dt = datetime.datetime.strptime(self.date_bare,fmt)
        except:
          continue

      if tri == 'dateparser':
        try:
          dt = dateparser.parse(self.date_bare)
        except:
          continue

      if dt:
        date = dt.strftime('%d_%m_%Y')
        break

    return date

  def _sel_date(self, soup, sel={}):
    date = self._date_from_sel(soup,sel)
    return date

  def _date_from_sel(self, soup, sel={}):
    date = None

    find = sel.get('find','')
    get  = sel.get('get','')
    fmt  = sel.get('fmt',"%Y-%m-%d")

    sep         = sel.get('split','')
    split_index = sel.get('split_index',0)

    if not find:
      return 

    els = soup.select(find)
    if not els:
      return

    for c in els:
      if get:
        if get == 'attr':
          attr = sel.get('attr','')
          if c.has_attr(attr):
            self.date_bare = c[attr]
            break
  
        if get == 'text':
          txt = c.get_text()
          if util.get(sel,'text.strip_n',1):
            txt = string.strip_n(txt)
  
          lopt = util.get(sel,'text.lines',{})
          if len(lopt):
            found = 0
            lines = txt.split("\n")
            txt = None
            re_match = util.get(lopt,'re_match','')
            for line in lines:
              m = re.match(rf'{re_match}',line)
              if m:
                txt = m.group(1)
                found = 1
                break
  
          if txt:
            self.date_bare = txt
            break
  
    if self.date_bare:
      if sep:
        spl = self.date_bare.split(sep)
        s = ''
        if len(spl) >= split_index + 1:
          s = spl[split_index]
        else:
          s = spl[0]
  
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

    d_parse_author = {}

    return self

  def itm_process_search(self,ref={}):
    app  = self.app
    soup = util.get(ref,'soup',app.soup)
    itm  = util.get(ref,'itm',{})

    # modes: 
    #   author, date
    mode  = util.get(ref,'mode','')

    search  = util.get(itm,'search',{})
    if not len(search):
      return self

    css    = util.get(search,'css','')
    r_text = util.get(search,'text')
    if css:
      els = soup.select(css)
      for el in els:
        if r_text:
          txt = el.get_text()
          if type(r_text) in [dict]:
            r_lines = util.get(r_text,'lines')
            if r_lines:
              lines = string.split_n_trim(txt)
              if type(r_lines) in [dict]:
                r_match  = util.get(r_lines,'match')
                if r_match and type(r_match) in [dict]:
                  pat  = util.get(r_match,'pat')
                  patc = re.compile(rf'{pat}')
                  index_name  = util.get(r_match,'name',1)

                for line in lines:
                  if patc:
                    m = re.match(patc,line)
                    if m:
                      if mode == 'author':
                        name = m.group(index_name)
                        if name:
                          self.d_parse_author.update({ 'name' : name})

    return self

  def gah_process_nu(self,ref={}):
    app  = self.app
    soup = util.get(ref,'soup',app.soup)
    itm  = util.get(ref,'itm',{})

    for k in util.qw('name url'):
      sel = itm.get(k)
  
      if not sel:
        continue
  
      find  = sel.get('find','')
      get   = sel.get('get','')
      sep   = sel.get('split','')
  
      if not find:
        continue
  
      c = soup.select_one(find)
      if not c:
        continue
  
      v = None
      if get == 'attr':
        attr = sel.get('attr','')
        if c.has_attr(attr):
          v = c[attr]
  
      if get == 'text':
        v = c.get_text()
  
      if v == None:
        continue
  
      if k == 'name':
        if sep:
          v = v.split(sep)[0]
        v = string.strip_nq(v)
  
      if k == 'url':
        url = v 
        auth_url  = util.url2base(app.page.baseurl, url)
        print(f'[PageParser] found author url: {auth_url}')
  
      self.d_parse_author.update({ k : v })

    return self

  def get_author_sels(self,ref={}):
    '''
      input:
        sels - LIST 
        soup - BeautifulSoup instance
    '''
    app = self.app
    soup = util.get(ref,'soup',app.soup)

    sels = util.get(ref,'sels',[])

    for itm in sels:
      self.d_parse_author = {}

      r = { 
        'itm'  : itm,
        'soup' : soup,
        'mode' : 'author',
      }
      self                     \
        .gah_process_nu(r)     \
        .itm_process_search(r) \

      auth_bare = util.get(self.d_parse_author,'name')
      if auth_bare:
        print(f'[PageParser] found author name: {auth_bare}')
        self.auth_obj.parse(self.d_parse_author)
        break

    return self

  def get_author_meta(self,ref={}):
    app = self.app
      
    if not self.meta:
      self.import_meta()

    sels = []
    sels.extend( app._cnf('PageParser.get_author_meta.sels',[]) )
    sels.extend( app._site_data('PageParser.get_author_meta.sels',[]) )

    self.get_author_sels({ 
        'sels' : sels,
        'soup' : self.meta
    })
    
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
    app = self.app

    sels = []
    sels.extend( app._cnf('PageParser.get_author_html.sels',[]) )
    sels.extend( app._site_data('PageParser.get_author_html.sels',[]) )

    self.get_author_sels({ 
      'sels' : sels,
      'soup' : app.soup,
    })

    return self

