
import os,re,sys
from pathlib import Path

import Base.DBW as dbw
import Base.Util as util
import Base.String as string
import Base.Const as const

import Base.Rgx as rgx
import plg.projs.db as projs_db

from plg.projs.Prj import Prj

import jinja2

import yaml

from Extern.Pylatex import Package
from Extern.Pylatex.base_classes import Command, Options

#from pylatex import Package
#from pylatex.base_classes import Command, Options

from Base.Mix.mixCmdRunner import mixCmdRunner
from Base.Mix.mixLogger import mixLogger
from Base.Mix.mixLoader import mixLoader
from Base.Mix.mixGetOpt import mixGetOpt
from Base.Mix.mixFileSys import mixFileSys

from Base.Zlan import Zlan
from Base.Core import CoreClass

class Tex(CoreClass):

  def _tex_head(self, ref = {}):
    t = self._tex_tmpl_render('head.tex',ref)

    tex_lines = t.split('\n')
    return tex_lines

  def _tex_preamble(self, ref = {}):
    r_preamble = ref.get('preamble',{})

    if not len(r_preamble):
      # preamble name
      name = ref.get('name','')
      if name:
        names = self._tex_preamble_names()
        if name in names:
          dir = self._dir('tex.preambles',name)
          pack_file = os.path.join(dir,'packs.yaml')
          if os.path.isfile(pack_file):
            r_preamble = { 'pack_file' : pack_file }

    if not len(r_preamble):
      return self

    tex_lines = []

    pack_file = r_preamble.get('pack_file','')
    pack_data = {}
    if os.path.isfile(pack_file):
      with open(pack_file) as f:
        pack_data = yaml.full_load(f)

    if len(pack_data):
      pack_list    = pack_data.get('list',[])
      pack_options = pack_data.get('options',{})

      for pack in pack_list:
        opts = pack_options.get(pack,{})

        opts_bool = []
        opts_dict = {}
        for k, v in opts.items():
           if type(v) in [bool] and v == True:
             opts_bool.append(k)
           else:
             opts_dict.update({ k : v })

        s = Package(pack,options=Options(*opts_bool, **opts_dict)).dumps()
        tex_lines.append(s)

    return tex_lines

  def tex_compile(self, ref = {}):


    return self

