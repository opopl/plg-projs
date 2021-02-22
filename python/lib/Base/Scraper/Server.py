
import os,sys,re

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import json

from Base.Zlan import Zlan
from Base.Core import CoreClass

import web

class Srv(CoreClass):
  urls = (
    '/', 'r_html_index',
    '/html/pages/(\d+)', 'r_html_page'
    '/json/pages/(\d+)', 'r_json_page'
  )

  def __init__(self,ref={}):
    super().__init__(ref)

  def start(self):
    sys.argv = []
    self.app = web.application(self.urls, globals())
    try:
      self.app.run()
    except: 
      import pdb; pdb.set_trace()

    return self

class r_html_index(Srv):
  def GET(self):
    return "Hello, world!"
  
class r_html_page(Srv):
  def GET(self,rid):
    page = self.engine._page_from_rid(rid)
    return rid

class r_json_page(Srv):
  def GET(self,rid):
    page = self.engine._page_from_rid(rid)
    return rid
