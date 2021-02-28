#!/usr/bin/env python3

import web

from Base.Scraper.Engine import BS
import Base.Util as util

import os,sys
import json
import dateparser

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
    return globals()

class r_html_page_rid_tipe:
  def GET(self,rid,tipe):
    rid_html = ee._file_rid({ 
      'rid'  : rid, 
      'tipe' : tipe, 
      'ext'  : 'html', 
    })

    h = ''
    web.header('Content-Type', 'text/html; charset=utf-8')

    if os.path.isfile(rid_html):
      with open(rid_html,'r') as f:
        h = f.read()

    return h

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
    j = json.dumps(page.__dict__, ensure_ascii=False)
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

    '/html/pages'            , 'r_html_pages'         ,
    '/html/page/(\d+)/(\w+)' , 'r_html_page_rid_tipe' ,

    '/js/bundle'             , 'r_js_bundle'          ,
  )

  sys.argv = [ __file__ ]

  app = web.application(urls, globals())
  app.run()
