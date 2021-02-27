#!/usr/bin/env python3

import web

from Base.Scraper.Engine import BS
import Base.Util as util

import os,sys
import json

global ee

class r_html_index:
  def GET(self):
    return globals()

class r_html_pages:
  def GET(self):
    web.header('Content-Type', 'text/html; charset=utf-8')

    d = web.input()
    params = dict(d.items())
    pages = ee._db_get_pages({ 'where' : params })

    t = ee.template_env.get_template("list.t.html")
    h = t.render(pages=pages)

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
    pages = ee._db_get_pages({ 'where' : params })

    r  = { 
      'pages' : pages,
      'count' : len(pages),
    }

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
    '/',                'r_html_index',

    '/json/page/(\d+)', 'r_json_page',
    '/json/pages',      'r_json_pages',

    '/html/pages',      'r_html_pages',
  )

  sys.argv = [ __file__ ]

  app = web.application(urls, globals())
  app.run()
