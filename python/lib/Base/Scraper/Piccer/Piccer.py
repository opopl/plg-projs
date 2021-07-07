
import pickle

import time
import os,sys,re

import json
import pylatexenc

from Base.Mix.mixCmdRunner import mixCmdRunner
from Base.Mix.mixLogger import mixLogger
from Base.Mix.mixGetOpt import mixGetOpt

from Base.Mix.mixFileSys import mixFileSys

# load yaml/zlan - load_zlan, load_yaml
from Base.Mix.mixLoader import mixLoader

from Base.Scraper.Mixins.mxDB import mxDB

import Base.Util as util
from Base.Core import CoreClass

from Base.Scraper.PicBase import PicBase

class Piccer(CoreClass,
        mixLogger,
        mixCmdRunner,
        mixGetOpt,
        mixLoader,
        mixFileSys,

        mxDB,
    ):

    vars = {
      'mixCmdRunner' : {
        'cmds' : []
      }
    }

    urldata = []

    usage = '''
    PURPOSE
          This script is for managing pics 
    EXAMPLES
          r_piccer.py -z pics.zlan
    '''
  
    opts_argparse = [
      { 
         'arr' : '-c --cmd', 
         'kwd' : { 'help'    : 'Run command(s)' } 
      },
      { 
         'arr' : '-y --f_yaml', 
         'kwd' : { 
             'help'    : 'input YAML file',
             'default' : '',
         } 
      },
      { 
         'arr' : '-z --f_zlan',
         'kwd' : { 
             'help'    : 'input ZLAN file',
             'default' : '',
         } 
      }
    ]

    def __init__(self,ref={}):

      for k, v in ref.items():
        setattr(self, k, v)

    def init(self):
        print('[init] start')

        acts = [
          'load_yaml',
          'load_zlan',
        ] 

        util.call(self, acts)

        return self

    def get_opt_apply(self):
      if not self.oa:
        return self
  
      for k in util.qw('f_yaml f_zlan'):
        v = util.get(self,[ 'oa', k ])
        m = re.match(r'^f_(\w+)$', k)
        if m:
          ftype = m.group(1)
          self.files.update({ ftype : v })
  
      return self

    def get_opt(self):
      if self.skip_get_opt:
        return self
  
      mixGetOpt.get_opt(self)
  
      self.get_opt_apply()
  
      return self

    def main(self):
      acts = [
        'get_opt',
        'do_cmd',
      ]
  
      util.call(self,acts)


      return self

    def import_pic(self, ref = {}):

      self.pic = PicBase(ref)

      self.pic.grab()

      return self

    def grab_pics(self,ref = {}):

      urldata = ref.get('urldata',[])
      if not len(urldata):
        urldata = getattr(self,'urldata',[]) 
  
      self.page_index = 0
      while len(urldata):
        d = urldata.pop(0)
        self.import_pic(d)
  
      return self

    def c_run(self):
      print(f'command: run')

      acts = [
        'init' ,
        'grab_pics' ,
      ]

      util.call(self,acts)

      return self
