
import os,sys,re

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

from Base.Zlan import Zlan
from Base.Core import CoreClass

import web



class Srv(CoreClass):
  urls = (
    '/', 'r_html_index',
    '/pages/(\d+)', 'r_html_page'
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
    return rid
