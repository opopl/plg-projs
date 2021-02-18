
import os,sys,re
import datetime
import cyrtranslit

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

from Base.Scraper.PageParser import RootPageParser

class PageParser(RootPageParser):
  def generate_ii(self,ref={}):
    super().generate_ii(ref)

    return self

  def get_date(self,ref={}):
    super().get_date(ref)

    app = self.app
    if app.page.get('date'):
      return self

    parts = self.url_parts
    path  = self.url_path

    return self

  def get_date_html(self,ref={}):
    super().get_date_html(ref)

    app = self.app
    if app.page.get('date'):
      return self

    return self

  def get_date_ld_json(self,ref={}):
    super().get_date_ld_json(ref)

    app = self.app
    if app.page.get('date'):
      return self

    return self

  def get_date_url(self,ref={}):
    super().get_date_url(ref)

    app = self.app
    if app.page.get('date'):
      return self

    return self

  def get_date_meta(self,ref={}):
    super().get_date_meta(ref)

    app = self.app
    if app.page.get('date'):
      return self

    return self

  def clean(self,ref={}):
    super().clean(ref)

    app = self.app
    soup = app.soup

    return self

  # import date from input string
  def _date_from_bare(self, txt=None):
    date = super()._date_from_bare(txt)
    if date:
      return date

    #date = None
    return date
