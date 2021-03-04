#!/usr/bin/env python3

import web

from bs4 import BeautifulSoup, Comment

from Base.Scraper.Engine import BS
from Base.Scraper.Engine import Page
from Base.Scraper.Pic import Pic

import Base.Util as util

import os,sys
import json
import dateparser
import urllib.parse

global ee

class r_js_bundle:
  def GET(self):
    file = ee._file('bundle_js.dist')
    with open(file,'r') as f:
      js = f.read()

    web.header('Content-Type', 'application/javascript; charset=utf-8')
    return js

class r_html_index:
  def GET(self):
    raise web.seeother(f'/html/pages')

class r_html_page_rid:
  def GET(self,rid):
    raise web.seeother(f'/html/page/{rid}/clean')

class r_html_page_rid_tipe:
  def get_html(self,ref={}):
    rid  = util.get(ref,'rid','')
    tipe = util.get(ref,'tipe','')

    css    = util.get(ref,'css','')
    xpath  = util.get(ref,'xpath','')

    file_html = ee._file_rid({ 
      'rid'  : rid, 
      'tipe' : tipe, 
      'ext'  : 'html', 
    })

    src_code = ''
    if os.path.isfile(file_html):
      with open(file_html,'r') as f:
        src_code = f.read()

    src_html = src_code

    if css or xpath:
      bs = BeautifulSoup(src_code,'html5lib')
      if css:
        els = bs.select(css)
        txt = []
        for el in els:
          txt.append(str(el))

        src_code = '\n'.join(txt)
        src_html = '<br>\n'.join(txt)

    #html = encodeURIComponent(html);

    return { 
        # iframe
        'src_html' : src_html,

        # textarea
        'src_code' : src_code,
    }

  def req(self,ref={}):
    rid  = util.get(ref,'rid','')
    tipe = util.get(ref,'tipe','')

    d = web.input()
    params = dict(d.items())

    xpath = params.get('xpath','')
    css   = params.get('css','')

    r = self.get_html({ 
        'rid'   : rid,
        'tipe'  : tipe,
        'xpath' : xpath,
        'css'   : css,
    })

    return r

  def POST(self,rid,tipe,suffix=''):

    r = self.req({ 'rid' : rid, 'tipe' : tipe })
    src_code = r.get('src_code','')
    src_html = r.get('src_html','')

    h = None
    ct = 'text/html; charset=utf-8'
    if suffix == 'src':
      h = src_html

    elif suffix == 'code':
      h = src_code
      ct = 'text/plain; charset=utf-8'

    web.header('Content-Type', ct)

    return h

  def GET(self,rid,tipe,suffix=''):

    r = self.req({ 'rid' : rid, 'tipe' : tipe })
    src_code = r.get('src_code','')
    src_html = r.get('src_html','')

    h = None

    page = ee._page_from_rid(rid)

    ct = 'text/html; charset=utf-8'
    if not suffix:
      src_uri = f'/html/page/{rid}/{tipe}/src'

      #data:text/html;charset=utf-8,{{ src }}
      #src_code = urllib.parse.quote(src_code,safe='')

      t = ee.template_env.get_template("page.t.html")
      h = t.render(
          page=page.dict(),
          src_uri=src_uri,
          src_code=src_code,
          tipe=tipe,
          rid=rid,
          iframe = { 
            'sandbox' : ''
          }
      )

    elif suffix == 'src':
      h = src_html

    elif suffix == 'code':
      h = src_code
      ct = 'text/plain; charset=utf-8'

    web.header('Content-Type', ct)

    return h 

class r_img_inum:
  def GET(self,inum):
    pic = Pic({ 
      'app'  : ee,
      'inum' : inum,
    })
    path = pic.path or ''

    iraw = ''
    if os.path.isfile(path):
      ct = pic.ct
      web.header('Content-Type', ct)
      with open(path,'rb') as f:
        iraw = f.read()

    return iraw

class r_html_pages:
  def h_pages(self,params={}):

    cols = ee.cols['pages']

    where = {}
    for k in cols:
      v = params.get(k,'')
      v.strip()
      if v:
        where[k] = v

    r = ee._db_get_pages({ 'where' : where })

    if not r:
      return ''

    pages = r.get('pages',[])
    cols  = r.get('cols',[])

    t = ee.template_env.get_template("pages.t.html")
    h = t.render(pages=pages,cols=cols)

    return h

  def POST(self):
    web.header('Content-Type', 'text/html; charset=utf-8')

    d = web.input()
    params = dict(d.items())

    date = params.get('date','')
    if date:
      dt = dateparser.parse(date)
      date = dt.strftime('%d_%m_%Y')
      params.update({ 'date' : date })

    h = self.h_pages(params)

    return h

  def GET(self):
    web.header('Content-Type', 'text/html; charset=utf-8')

    d = web.input()
    params = dict(d.items())

    h = self.h_pages(params)

    return h

class r_json_pages:
  def POST(self):
    d = web.data()
    web.header('Content-Type', 'application/json; charset=utf-8')
    return ''

  def GET(self):
    web.header('Content-Type', 'application/json; charset=utf-8')

    d = web.input()
    params = dict(d.items())

    r = ee._db_get_pages({ 'where' : params })

    j = json.dumps(r, ensure_ascii=False)

    return j

class r_json_page:
  def GET(self,rid):
    page = ee._page_from_rid(rid)
    web.header('Content-Type', 'application/json; charset=utf-8')
    #j = json.dumps(page.__dict__, ensure_ascii=False)
    j = json.dumps(page.dict(), ensure_ascii=False)
    return j

if __name__ == "__main__":
  r = { 
    'files' : {
      'script' : os.path.realpath(__file__),
    },
    'dirs' : {
      'bin' : os.path.dirname(__file__),
    }
  }
  
  ee = BS(r)
  ee.main()
  
  urls = (
    '/'                      , 'r_html_index'         ,

    '/json/page/(\d+)'       , 'r_json_page'          ,
    '/json/pages'            , 'r_json_pages'         ,

    '/html/pages(?:/|)'      , 'r_html_pages'         ,

    '/html/page/(\d+)/(\w+)(?:/(\w*)|)' , 'r_html_page_rid_tipe' ,

    '/html/page/(\d+)'       , 'r_html_page_rid'      ,


    '/img/(\d+)'             , 'r_img_inum'           ,

    '/js/bundle'             , 'r_js_bundle'          ,
  )

  sys.argv = [ __file__ ]

  app = web.application(urls, globals())
  app.run()
