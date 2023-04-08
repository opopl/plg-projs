
import Base.DBW as dbw

import Base.Util as util
import Base.String as string
import Base.Const as const

import os,re,sys
from pathlib import Path
import shutil


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
    proj       = ref.get('proj',self.proj)
    target     = ref.get('target','')
    trg_import = ref.get('trg_import','')

    tfile_import = self._dir('lts_root',f'{proj}.bld.{trg_import}.yml')
    db_file = self.prj.db_file

    ok = True
    ok = ok and target and trg_import
    ok = ok and ( target != trg_import )
    ok = ok and os.path.isfile(tfile_import)
    if not ok:
      print(f'Import target file does not exist!')
      return self

    tfile_new = self._dir('lts_root',f'{proj}.bld.{target}.yml')

    shutil.copyfile(tfile_import, tfile_new)

    if not os.path.isfile(tfile_new):
      print(f'New target file not created!')
      return self

    sec = f'_bld.{target}'
    ins_trg = {
      'proj'      : proj,
      'target'    : target,
    }
    dbw.insert_update_dict({
        'db_file'  : db_file,
        'table'    : 'targets',
        'insert'   : ins_trg,
        'on_list'  : ['proj','target']
    })

    return self
