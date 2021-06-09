
from Base.Core import CoreClass

class Page(CoreClass):

  app     = None

  baseurl = None
  host    = None
  rid     = None
  site    = None
  url     = None
  url_srv = None

  pics    = []
  imgbase = None

  ii_full = None
  tags    = None

  limit   = None

  title   = None
  title_h = None

  author_id       = None
  author_id_first = None

  # depth of link following
  depth     = 0

  date = None

  def __init__(page,ref={}):
    super().__init__(ref)

  def dict(page):
    data = {}
    for k in dir(page):
      if k in [ '__dict__', '__module__' ]:
        continue

      v = getattr(page,k)
      if type(v) in [ dict,list,str,int ]:
        data.update({ k : v })

    return data

  def _cite_data(page):
    cite_data = {}

    return cite_data
      

