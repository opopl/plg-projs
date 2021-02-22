
import os,sys,re

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

from Base.Zlan import Zlan
from Base.Core import CoreClass

import web

from Base.Scraper.Engine import BS

#r = { 
  #'files' : {
    #'script' : os.path.realpath(__file__)
  #},
#}
r = {}

#bs = BS(r)

urls = (
  '/', 'r_html_index',
  '/pages/(\d+)', 'r_html_page'
)

class r_html_index:
  def GET(self):
    return "Hello, world!"

class r_html_page:
  def GET(self,rid):
    return rid

class Srv(CoreClass):
  def __init__(self,ref={}):
    super().__init__(ref)

  def run(self):

    self.app = web.application(urls, globals())
    self.app.run()

    return self
