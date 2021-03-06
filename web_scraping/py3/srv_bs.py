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

import lxml

from html import escape

global car

class r_js_bundle:
  def GET(self):
    file = car._file('bundle_js.dist')
    with open(file,'r') as f:
      js = f.read()

    web.header('Content-Type', 'application/javascript; charset=utf-8')
    return js

class r_html_index:
  def GET(self):
    raise web.seeother(f'/html/pages')

class r_html_page_last:
  def GET(self):
    rid = car._rid_last()
    raise web.seeother(f'/html/page/{rid}/clean')

class r_html_page_rid:
  def GET(self,rid):
    raise web.seeother(f'/html/page/{rid}/clean')

class r_html_page_rid_tipe:
  def req(self,ref={}):
    rid  = util.get(ref,'rid','')
    tipe = util.get(ref,'tipe','')

    d = web.input()
    params = dict(d.items())

    rr = { 'rid' : rid, 'tipe' : tipe }
    for k in util.qw('xpath css act'):
      rr[k] = params.get(k,'')

    r = car.get_html(rr)

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

    page = car._page_from_rid(rid)

    ct = 'text/html; charset=utf-8'
    if not suffix:
      src_uri = f'/html/page/{rid}/{tipe}/src'

      #data:text/html;charset=utf-8,{{ src }}
      #src_code = urllib.parse.quote(src_code,safe='')

      src_code_e = escape(src_code)

      t = car.template_env.get_template("page.t.html")
      h = t.render(
          page=page.dict(),
          src_uri=src_uri,
          src_code=src_code_e,
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
      'app'  : car,
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

    cols = car.cols['pages']

    where = {}
    for k in cols:
      v = params.get(k,'')
      v.strip()
      if v:
        where[k] = v

    r = car._db_get_pages({ 'where' : where })

    if not r:
      return ''

    pages = r.get('pages',[])
    cols  = r.get('cols',[])

    t = car.template_env.get_template("pages.t.html")
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

class r_json_authors:
  def POST(self):
    web.header('Content-Type', 'application/json; charset=utf-8')

    d = web.input()
    params = dict(d.items())

    r = car._db_get_authors({ 'where' : params })

    j = json.dumps(r, ensure_ascii=False)
    return j

class r_json_pages:
  def POST(self):
    d = web.data()
    web.header('Content-Type', 'application/json; charset=utf-8')
    return ''

  def GET(self):
    web.header('Content-Type', 'application/json; charset=utf-8')

    d = web.input()
    params = dict(d.items())

    r = car._db_get_pages({ 'where' : params })

    j = json.dumps(r, ensure_ascii=False)
    return j

class r_json_page:
  def GET(self,rid):
    page = car._page_from_rid(rid)
    web.header('Content-Type', 'application/json; charset=utf-8')
    #j = json.dumps(page.__dict__, ensure_ascii=False)
    j = json.dumps(page.dict(), ensure_ascii=False, indent=4)
    return j

class r_add_page:
  def GET(self):
    d = web.input()
    params = dict(d.items())

  def POST(self):
    d = web.input()
    params = dict(d.items())

if __name__ == "__main__":
  r = { 
    'files' : {
      'script' : os.path.realpath(__file__),
    },
    'dirs' : {
      'bin' : os.path.dirname(__file__),
    }
  }
  
  car = BS(r)
  car.main()
  
###urls
  urls = (
    '/'                      , 'r_html_index'         ,

    '/json/page/(\d+)'       , 'r_json_page'          ,
    '/json/pages'            , 'r_json_pages'         ,

    '/json/authors'          , 'r_json_authors'         ,

    '/html/pages(?:/|)'      , 'r_html_pages'         ,

    '/html/page/(\d+)/(\w+)(?:/(\w*)|)' , 'r_html_page_rid_tipe' ,

    '/html/page/(\d+)'       , 'r_html_page_rid'      ,
    '/html/page/last'        , 'r_html_page_last'      ,

    '/add/page'              , 'r_add_page'           ,

    '/img/(\d+)'             , 'r_img_inum'           ,

    '/js/bundle'             , 'r_js_bundle'          ,
  )

  sys.argv = [ __file__ ]

  app = web.application(urls, globals())
  app.run()
