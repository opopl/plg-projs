#!/usr/bin/env python3

import web

from Base.Scraper.Engine import BS
from Base.Scraper.Server import Srv
import os

#r = { 
  #'files' : {
    #'script' : os.path.realpath(__file__)
  #},
#}
r = {}

#bs = BS(r)

urls = (
  '/', 'route_index',
  '/pages/(\d+)', 'route_page'
)

class index:
  def GET(self):
    return "Hello, world!"

class page:
  def GET(self,rid):
    return rid


if __name__ == "__main__":
    app = web.application(urls, globals())
    app.run()
