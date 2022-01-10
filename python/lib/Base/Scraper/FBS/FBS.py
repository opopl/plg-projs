
from selenium import webdriver

from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException

import selenium.webdriver.support.ui as ui

#import xml.etree.ElementTree as et
from lxml import etree
import lxml.html

from io import StringIO, BytesIO

import pickle
import logging

import time
import os,sys,re

import json
import pylatexenc

from Base.Mix.mixCmdRunner import mixCmdRunner
from Base.Mix.mixLogger import mixLogger
from Base.Mix.mixGetOpt import mixGetOpt

from Base.Mix.mixFileSys import mixFileSys

from Base.Mix.mixLg import mixLg
from Base.Mix.mixDrv import mixDrv
from Base.Mix.mixEval import mixEval

# load yaml/zlan - load_zlan, load_yaml
from Base.Mix.mixLoader import mixLoader

from Base.Scraper.Mixins.mxDB import mxDB

import Base.Util as util
from Base.Core import CoreClass

from Base.Scraper.FBS.FbPost import FbPost

from Base.Scraper.FBS.ShellFBS import ShellFBS

from Base.Scraper.PicBase import PicBase

from dict_recursive_update import recursive_update


#p [ x['clist'] for x in clist if 'clist' in x and len(x['clist'])]
 
class FBS(CoreClass,
        mixLogger,
        mixCmdRunner,
        mixGetOpt,
        mixLoader,
        mixFileSys,

        mxDB,
        mixLg,
        mixEval,
        mixDrv,
    ):

    vars = {
      'mixCmdRunner' : {
        'cmds' : []
      }
    }

    urldata = []

    email = None
    password = None

    # browser (Firefox) profile
    fp = None

    flags = { 
     'done' : { 
        'auth' : 0 
      }
    }

    # what is done
    done = {}

    driver = None

    etree = lxml.etree

    # accessible via _cfg() method
    config = {}

    # FbPost instance
    fbpost = None

    post_data = {}

    usage = '''
    PURPOSE
       This script will scrape FB posts
    EXAMPLES
       r_fbs.py -y fb.yaml -z fb.zlan
    '''

    # ShellFBS instance
    shell = None

    do_shell = True
  
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
      },
      { 
         'arr' : '-l --log', 
         'kwd' : { 'help' : 'Enable logging' } 
      },
    ]

    def __init__(self,ref={}):

      for k, v in ref.items():
        setattr(self, k, v)



    def _host2site(self,host=''):
        hs = self._cfg('host2site',[])
        site = host
        if not host:
          return site

        for h in hs:
          r = h[1]
          pat = r.get('pat','')
          if pat:
            m = re.match(rf'{pat}',host)
            if m:
              site = h[0]
              break

        return site

    def init(self):
      print('[init] start')

      acts = [
        # mixLoader:  load_yaml(), load_zlan()
        'load_yaml',   
        'load_zlan',   
        'evl',   
        # mixLg: init_lg(path)
        'init_lg',
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

    def shell_loop(self):
      if not self.do_shell:
        return self

      self.shell = ShellFBS({ 'fbs' : self })
      try:
        self.shell.cmdloop()
      except:
        self.shell.cmdloop()

      return self

    def main(self):
      acts = [
        'get_opt',
        'do_cmd',
        'shell_loop',
      ]
  
      util.call(self,acts)

      return self

    def parse_fbpost(self, ref = {}):

      r = { 
         'app'    : self,
         'driver' : self.driver
      }
      for k in util.qw('url tags title date ii author_id'):
        v = ref.get(k)
        if v != None:
          r[k] = v

      c = self.get('class.fbpost',{})
      if c and len(c):
        recursive_update(r, c)

      if not self.fbpost:
        self.fbpost = FbPost(r)

        self.fbpost.process()

      return self

    def grab_pages(self,ref = {}):

      urldata = ref.get('urldata',[])
      if not len(urldata):
        urldata = getattr(self,'urldata',[]) 
  
      self.page_index = 0
      while len(urldata):
        d = urldata.pop(0)
        self.parse_page(d)
  
#        if self.page.limit:
          #if self.page_index == self.page.limit:
             #break
  
      #self.parsed_report()

      return self

    def c_run(self):

        acts = [
          'init' , 
          'grab_pages' , 
        ] 

        util.call(self,acts)

        return self



    def parse_page(self,ref={}):
        url = ref.get('url')
        if not url:
          return self
        
        u = util.url_parse(url)
        host = u.get('host','')
        site = self._host2site(host)

        if site == 'facebook':
          self.parse_fbpost(ref)
          return self

        self.parse_page_general(ref)

        return self

    def page2tree(self,ref={}):
        try:
          self.xtree = lxml.html.parse(StringIO(self.driver.page_source))
          self.xroot = self.xtree.getroot()
        except:
          print('Fail to parse page via lxml.html')
          e = sys.exc_info()
          print(f'fail: {e}')

        return self

    def parse_page_general(self,ref={}):
        url = ref.get('url')
        if not url:
          return self

        acts = [
          [ 'drv_get', [ url ]],
          'page2tree'
        ] 

        util.call(self,acts)

        return self



    # cfg = self._cfg('driver.click.limit')
    def _cfg(self,path='',default=None):
        if not (path and len(path)):
          cval = self.config
          return cval
        else:
          if isinstance(path,str):
            path = f'config.{path}'
          elif isinstance(path,list):
            path.insert(0,'config')

        cval = util.get(self,path,default)
        return cval

    def _tex_preamble(self):

        tex = []
        with open('_post_preamble.tex','r') as f:
          tex.extend( [ line.rstrip('\n') for line in f ] )

        return tex
  
  
