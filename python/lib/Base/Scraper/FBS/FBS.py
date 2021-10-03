
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

    etree = lxml.etree

    # accessible via _cfg() method
    config = {}

    f_cookies = "cookies.pkl"

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

      if not self.email:
        self.email = os.environ.get('FB_LOGIN')

      if not self.password:
        self.password = os.environ.get('FB_PASS')

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
        #'init_drv',
      ] 

      util.call(self, acts)

      return self





    def init_drv(self):
      self.lg('fbs','info','[init_drv] start')

      if not self.fp:
        fp = webdriver.FirefoxProfile()

        prf = self._cfg('driver.firefox.profile.preferences',{})
        for k, v in prf.items():
          fp.set_preference(k,v)
 
        self.fp = fp

        self.lg('fbs','info','[init_drv] init firefox profile')

      if not self.driver:
        driver = webdriver.Firefox(self.fp)
        self.driver = driver

        self.lg('fbs','info','[init_drv] init firefox driver')

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

      r = { 'app' : self }
      for k in util.qw('url tags title date ii author_id'):
        v = ref.get(k)
        if v != None:
          r[k] = v

      c = self.get('class.fbpost',{})
      if c and len(c):
        recursive_update(r, c)

      self.post = FbPost(r)
      import pdb; pdb.set_trace()

      self.auth_fb()
      self.post.process()

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
          #'save_cookies' , 
        ] 

        util.call(self,acts)

        return self

    def save_cookies(self):
        print(f'Saving cookie file: {self.f_cookies}')

        pickle.dump( self.driver.get_cookies(), open(self.f_cookies,"wb"))

        return self

    def auth_fb(self):
        if self._done('auth_fb'):
          return self

        self.login_fb()

        if not os.path.isfile(self.f_cookies):
          self.login_fb_send()
          return self

        self.load_cookies()

        self._done('fb_auth',1)

        return self

    def load_cookies(self):
        if not os.path.isfile(self.f_cookies):
          return self

        self.lg('fbs','info',f'Loading cookie file: {self.f_cookies}')

        cookies = pickle.load(open(self.f_cookies, "rb"))
        if self.driver:
          for cookie in cookies:
            self.driver.add_cookie(cookie)

        time.sleep(2) 

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

    def login_fb(self):

        url = self._cfg('url.site.facebook.login')

        try:
          self.driver.get(url)
          element = WebDriverWait(self.driver, 10).until(
             EC.presence_of_element_located((By.ID, "m_login_email"))
          )
          time.sleep(1)
        except:
          ei = sys.exc_info()
          print(f'[FBS] url get fail: {url}')
          print(f'fail: {ei}')

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

    def _done(self,key,val=None):
        r = None
        if val == None:
          r = util.get(self,f'done.{key}')
        else:
          r = val
          self.done.update({ key : val })

        return r
    
    def _tex_preamble(self):

        tex = []
        with open('_post_preamble.tex','r') as f:
          tex.extend( [ line.rstrip('\n') for line in f ] )

        return tex
  
    def login_fb_send(self):
        #email_element = self.driver.find_element_by_id('email')
        email_element = self.driver.find_element_by_id('m_login_email')
        email_element.send_keys(self.email) # Give keyboard input
 
        #password_element = self.driver.find_element_by_id('pass')
        password_element = self.driver.find_element_by_id('m_login_password')
        password_element.send_keys(self.password) # Give password as input too
 
        #login_button = self.driver.find_element_by_id('loginbutton')
        login_button = self.driver.find_element_by_id('login_password_step_element')
        login_button.click() # Send mouse click

        time.sleep(2) # Wait for 2 seconds for the page to show up

        self.save_cookies()

        return self
