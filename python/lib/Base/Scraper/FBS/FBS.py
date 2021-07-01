
from selenium import webdriver

from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException

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

from Base.Scraper.FBS.FbPost import FbPost

LOGIN_URL = 'https://mobile.facebook.com/login.php'

#p [ x['clist'] for x in clist if 'clist' in x and len(x['clist'])]
 
class FBS(CoreClass,
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

    email = None
    password = None

    # Firefox profile
    fp = None

    f_cookies = "cookies.pkl"

    post_data = {}

    usage = '''
    PURPOSE
          This script will scrape FB posts
    EXAMPLES
          r_fbs.py -y fb.yaml -z fb.zlan
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

    def init(self):
        print('[init] start')

        acts = [
          [ 'init_drv' ],
          [ 'load_yaml' ],
          [ 'load_zlan' ],
        ] 

        util.call(self, acts)

        return self

    def init_drv(self):
        print('[init_drv] init firefox driver')

        fp = webdriver.FirefoxProfile()

        fp.set_preference("dom.webnotifications.enabled",False)
        fp.set_preference("geo.enabled",False)
    
        self.fp = fp
    
        driver = webdriver.Firefox(fp)
        self.driver = driver

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
        [ 'get_opt' ],
        [ 'do_cmd' ],
      ]
  
      util.call(self,acts)

      import pdb; pdb.set_trace()

      return self

    def parse_post(self, ref = {}):

      r = { 'app' : self }
      for k in util.qw('url tags title date ii author_id'):
        v = ref.get(k)
        if v != None:
          r[k] = v

      self.post = FbPost(r)

      self.post.process()

      return self

    def grab_posts(self,ref = {}):

      urldata = ref.get('urldata',[])
      if not len(urldata):
        urldata = getattr(self,'urldata',[]) 
  
      self.page_index = 0
      while len(urldata):
        d = urldata.pop(0)
        self.parse_post(d)
  
#        if self.page.limit:
          #if self.page_index == self.page.limit:
             #break
  
      #self.parsed_report()

      return self

    def c_run(self):

        acts = [
            'init' , 
            'do_auth' , 
            'grab_posts' , 
            'save_cookies' , 
        ] 

        util.call(self,acts)

        return self

    def save_cookies(self):
        print(f'Saving cookie file: {self.f_cookies}')

        pickle.dump( self.driver.get_cookies(), open(self.f_cookies,"wb"))

        return self

    def do_auth(self):
        self.get_url_login()

        if not os.path.isfile(self.f_cookies):
          self.login()
          return self

        self.load_cookies()

        return self

    def load_cookies(self):
        if not os.path.isfile(self.f_cookies):
          return self

        print(f'Loading cookie file: {self.f_cookies}')

        cookies = pickle.load(open(self.f_cookies, "rb"))
        for cookie in cookies:
          self.driver.add_cookie(cookie)

        time.sleep(2) 

        return self

    def get_url_login(self):

        self.driver.get(LOGIN_URL)
        time.sleep(1)

        return self

    def _els_find(self,ref={}):
        elin = ref.get('el',self.driver)

        xpath = ref.get('xpath','')
        css   = ref.get('css','')

        els = None

        if xpath:
          try:
            els = elin.find_elements_by_xpath(xpath)
          except:
            pass

        if css:
          try:
            els = elin.find_elements_by_css_selector(css)
          except:
            pass
              
        return els

    def _el_src(self,ref={}):
        elin = ref.get('el',self.driver)

        parent = self._el_find({ 
          'el'    : elin,
          'xpath' : '..',
        })

        el_src = elin
        if parent:
          el_src = parent

        src = el_src.get_attribute('innerHTML')

        return src

    def _el_find(self,ref={}):
        elin = ref.get('el',self.driver)

        xpath = ref.get('xpath','')
        css   = ref.get('css','')

        el = None

        if xpath:
          try:
            el = elin.find_element_by_xpath(xpath)
          except:
            pass

        if css:
          try:
            el = elin.find_element_by_css_selector(css)
          except:
            pass
              
        return el

    def _els_comments(self,ref={}):
        elin = ref.get('el') or self.driver

        cmt_els = self._els_find({ 
          'xpath' : './/div[ @data-sigil="comment" ]',
          'el'    : elin
        })

        return cmt_els

    def _el_reply(self,ref={}):
        elin = ref.get('el') or self.driver

        reply = self._el_find({ 
          'el'    : elin,
          'xpath' : './/div[ @data-sigil="replies-see-more" ]'
        })

        return reply
    
    def _tex_preamble(self):

        tex = []
        with open('_post_preamble.tex','r') as f:
          tex = f.readlines()

        return tex
  
    def login(self):
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
