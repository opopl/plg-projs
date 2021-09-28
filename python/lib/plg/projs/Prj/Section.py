
import os,re,sys

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Rgx as rgx

from pathlib import Path

import jinja2

from Base.Core import CoreClass

class Section(
     CoreClass
  ):

  cols = [
    'author_id',
    'date',
    'fid',
    'file',
    'id',
    'parent',
    'pic',
    'pid',
    'proj',
    'projtype',
    'rootid',
    'sec',
    'tags',
    'title',
    'url',
  ]

  def __init__(self,args={}):
    CoreClass.__init__(self,args)

  def _record(self):
    r = self.__dict__
    return r
