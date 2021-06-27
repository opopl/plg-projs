
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



  def _cite_data(page):
    cite_data = {}

    return cite_data
      

