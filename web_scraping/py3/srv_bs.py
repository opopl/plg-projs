#!/usr/bin/env python3

import web

from Base.Scraper.Engine import BS
import Base.Util as util

import os,sys

r = { 
  'files' : {
    'script' : os.path.realpath(__file__),
  },
  'dirs' : {
    'bin' : os.path.dirname(__file__),
  },
  'vars' : {
    'mixCmdRunner' : {
      'cmds' : util.qw('init_bs')
    }
  }
}

ee = BS(r)
ee.main()

urls = (
  '/', 'r_html_index',
  '/json/pages/(\d+)', 'r_json_page'
)

class r_html_index:
  def GET(self):
    return globals()

class r_json_page:
  def GET(self,rid):
    page = ee._page_from_rid(rid)
    return str(self)

if __name__ == "__main__":
  sys.argv = [ __file__ ]
  app = web.application(urls, globals())
  app.run()
