
from Base.Core import CoreClass

import os,re,sys
from pathlib import Path

from Base.Mix.mixFileSys import mixFileSys

class Page(
    CoreClass,

    mixFileSys
  ):

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
      
  def _file_rid(page,ref={}):
    tipe = ref.get('tipe','cache')
    ext  = ref.get('ext','html')
    rid  = ref.get('rid',page.rid)

    ii_file = os.path.join(page._dir_ii({ 'rid' : rid }),f'{tipe}.{ext}')
    return ii_file

  def _dir_ii(page,ref={}):
    rid = ref.get('rid',page.rid)

    dir = page._dir('root',f'bs {rid}')

    return dir

  def _ii_full(page):
    date = page.get('date')
    site = page.site

    ii_num = page._ii_num()
    page.set({ 'ii_num' : ii_num })

    a_f = page.get('author_id_first')
    a_fs = f'.{a_f}' if a_f else ''

    ii_full = f'{date}.site.{site}{a_fs}.{ii_num}.{page.ii}'

    return ii_full
