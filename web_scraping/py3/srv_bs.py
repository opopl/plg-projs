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

class r_json_pages:
  def POST(self):
    web.header('Content-Type', 'application/json; charset=utf-8')
    return ''

  def GET(self):
    web.header('Content-Type', 'application/json; charset=utf-8')
    return ''

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
  )

  sys.argv = [ __file__ ]

  app = web.application(urls, globals())
  app.run()
