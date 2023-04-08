
import Base.DBW as dbw

import Base.Util as util
import Base.String as string
import Base.Const as const

import os,re,sys
from pathlib import Path

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Rgx as rgx

from dict_recursive_update import recursive_update

from Base.Scraper.Engine import BS
from Base.Scraper.Engine import Page
from Base.Scraper.Pic import Pic

class ltsTarget:
  def trg_new(self, ref = {}):
    target       = ref.get('target','')
    trg_import   = ref.get('trg_import','')

    ok = ok and target and ( target != trg_import )
    if not ok:
      return self

    acts = [
      [ 'author_move_db_pages_main', [ ref ] ],
      [ 'author_move_db_pages', [ ref ] ],
      [ 'author_move_db_projs', [ ref ] ],
      [ 'author_move_dat', [ ref ] ],
    ]

    util.call(self,acts)

    return self


 
