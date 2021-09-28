

import os,re,sys

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Rgx as rgx

from pathlib import Path

import jinja2

from Base.Core import CoreClass
from plg.projs.Prj.Section import Section

class ListSections(
     CoreClass
  ):

  # list of Section instances
  sections = []

  # rows from database query, e.g. dbw.select(...) - list of dicts 
  rows = []

  # first Section
  first = None

  def _names(self):
    names = list(map(lambda x: x.sec,self.sections))
    return names

  def __init__(self,args={}):
    self.sections = []
    self.rows = [] 
    self.first = None

    CoreClass.__init__(self,args)

    if len(self.rows):
      self.sections.extend( list(map(lambda x: Section(x), self.rows)) )

    if len(self.sections):
      self.first = self.sections[0]
