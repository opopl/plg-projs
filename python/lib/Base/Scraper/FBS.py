
from selenium import webdriver

from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException

import time
import os
import pickle
import re

import json
import pylatexenc

from Base.Mix.mixCmdRunner import mixCmdRunner
from Base.Mix.mixLogger import mixLogger
from Base.Mix.mixGetOpt import mixGetOpt
from Base.Mix.mixLoader import mixLoader

import Base.Util as util
from Base.Core import CoreClass

LOGIN_URL = 'https://mobile.facebook.com/login.php'

#p [ x['clist'] for x in clist if 'clist' in x and len(x['clist'])]
 
class FBS(CoreClass,
        mixLogger,
        mixCmdRunner,
        mixGetOpt,
        mixLoader
    ):

    vars = {
      'mixCmdRunner' : {
        'cmds' : []
      }
    }
    dirs = {}
    files = {}

    email = None
    password = None

    # Firefox profile
    fp = None

    f_cookies = "cookies.pkl"

    f_tex  = "post.tex"
    f_json = "post.json"

    comment_list = []
    comment_count = 0
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

        acts = [
          [ 'init_drv' ],
          [ 'load_yaml' ],
          [ 'load_zlan' ],
        ] 

        util.call(self, acts)

        return self

    def init_drv(self):
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
        v  = util.get(self,[ 'oa', k ])
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

    def get_posts(self):

      return self

    def c_run(self):

        acts = [
            'init' , 
            #'do_auth' , 
            'get_posts' , 
#            'get_url_post', 
           #[ 'post_loop_prev', [ { 'imax' : 70 } ] ],
            #'post_save_story' , 
            #'post_save_comments' , 
            #'post_wf_json' , 
            #'post_wf_tex' , 
            #'post_wf_html' , 
            #'save_cookies' , 
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
        time.sleep(1) # Wait for some time to load

        return self

    def get_url_post(self):
        # 18.01.2021
        self.driver.get('https://mobile.facebook.com/yevzhik/posts/3566865556681862')

        #self.driver.get('https://mobile.facebook.com/nitsoi.larysa/posts/938801726686200')
        #self.driver.get('https://mobilefacebook.com/olesia.medvedieva/posts/1637472103110572')
        return self

    def _el_comments(self,ref={}):
        el = ref.get('el') or self.driver

        cmt_els = None
        try:
          cmt_els = el.find_elements_by_xpath('.//div[ @data-sigil="comment" ]')
        except:
          pass

        return cmt_els

    def _el_reply(self,ref={}):
        elin = ref.get('el') or self.driver

        reply = None
        try:
          reply = elin.find_element_by_xpath('.//div[ @data-sigil="replies-see-more" ]')
        except:
          pass

        return reply

    def post_save_story(self,ref={}):
        elin = ref.get('el') or self.driver

        story = None
        try:
          story = elin.find_element_by_css_selector('.story_body_container')
        except:
          print('ERROR: could not find story!')
          raise
          pass

        if not story:
          return self

        story_txt = story.text
        story_src = story.get_attribute('innerHTML')

        self.post_data.update({
            'story'      : {
              'txt' : story_txt,
              'src' : story_src,
            }
        })
        
        return self

    def post_save_comments(self,ref={}):

        clist = self._post_clist()
        self.comment_list = clist

        self.post_data.update({
            'comments'      : clist,
            'comment_count' : self.comment_count,
        })

        print(f'Total Comment Count: {self.comment_count}')

        return self

    def _clist2tex(self,ref={}):
        clist = ref.get('clist') or self.comment_list

        tex = []
        if clist and len(clist):
          tex.append('\\begin{itemize}')
  
          for cmt in clist:
            tex_cmt = self._cmt2tex({ 'cmt' : cmt })
            tex.extend(tex_cmt)
  
          tex.append('\\end{itemize}')

        return tex

    def _cmt2tex(self,ref={}):
        cmt = ref.get('cmt')

        tex = []

        auth_bare = cmt.get('auth_bare')
        auth_url  = cmt.get('auth_url')
        clist_sub = cmt.get('clist',[])

        txt       = cmt.get('txt')

        if auth_bare:
          tex.append('\\iusr{' + auth_bare + '}')
          if auth_url:
            tex.append('\\url{' + auth_url + '}')

          tex.extend(['',txt,''])

          if len(clist_sub):
            tex.extend( self._clist2tex({ 'clist' : clist_sub }) )

        return tex

    def post_wf_json(self,ref={}):
        data = ref.get('data') or self.post_data

        data_js = json.dumps(data,ensure_ascii=False).encode('utf8')

        #with open(self.f_json, 'w') as f:
          #f.write(clist_js)

        with open(self.f_json, 'w', encoding='utf8') as f:
          json.dump(data, f, ensure_ascii=False)

        return self

    def post_wf_html(self,ref={}):

        html = self.driver.page_source
        with open(f'post.html', 'w', encoding='utf8' ) as f:
          f.write(html)

        return self

    def _tex_preamble(self):

        tex = []
        with open('_post_preamble.tex','r') as f:
          tex = f.readlines()

        return tex

    def post_wf_tex(self,ref={}):
        data = ref.get('data') or self.post_data

        clist = self.comment_list

        tex = []
        tex_clist = self._clist2tex({ 'clist' : clist })

        tex_story = util.get(self, 'post_data.story.txt', '')

        tex.extend(self._tex_preamble())
        tex.extend(['\\begin{document}'])
        tex.append(tex_story)
        tex.extend(['\\section{Comments}'])
        tex.extend(tex_clist)
        tex.extend(['\\end{document}'])

        texj = "\n".join(tex)

        with open(self.f_tex, 'w', encoding='utf8') as f:
          f.write(texj)

        return self

    def _post_clist(self,ref={}):
        '''
          clist = self._post_clist({ 'el'  : el })
          clist = self._post_clist({ 'els' : els })
        '''
        elin = ref.get('el') or self.driver

        cmt_els = ref.get('els')
        if not cmt_els:
          cmt_els = self._el_comments({ 'el' : elin })

        clist = []

        if not cmt_els:
          return clist

        for comment in cmt_els:
          cmt = {}

          reply = self._el_reply({ 'el' : comment })
          if reply:
            print('Reply click')
            reply.click()
            time.sleep(1)

            replies_inline = None
            try:
              replies_inline = comment.find_elements_by_xpath('.//div[ @data-sigil="comment inline-reply" ]')
            except:
              pass

            if replies_inline and len(replies_inline):
              print('Found more replies')
              clist_sub = self._post_clist({ 'els' : replies_inline })

              if len(clist_sub):
                print(f'cmt <- {len(clist_sub)} replies')
                cmt['clist'] = clist_sub

###cmt_process
          el_auth = comment.find_element_by_xpath('.//div[@class="_2b05"]')
          if el_auth:
            cmt['auth_bare'] = el_auth.text

            el_auth_link = el_auth.find_element_by_xpath('.//a')
            if el_auth_link:
              href = el_auth_link.get_attribute('href')
              if href:
                u = util.url_parse(href,{ 'rm_query' : 1 })
                q = u['query']
                qp = util.url_parse_query(q)

                auth_url_path = u['path']
                if u['path'] == '/profile.php':
                  if 'id' in qp:
                    id = qp.get('id')
                    auth_url_path = u['path'] + '?id=' + id

                cmt['auth_url_path'] = auth_url_path
                cmt['auth_url']      = util.url_join('https://www.facebook.com', auth_url_path)

          el_txt = comment.find_element_by_xpath('.//*[@data-sigil="comment-body"]')
          if el_txt:
            cmt['txt'] = el_txt.text
            cmt['src'] = el_txt.get_attribute('innerHTML')

          if len(cmt):
            clist.append(cmt)
            self.comment_count += 1

        return clist

    def post_loop_prev(self,ref={}):

        pv = None

        i    = 1
        imax = ref.get('imax') or 10

        while 1:
          try:
            pv = self.driver.find_element_by_id('see_prev_3566865556681862')
          except:
            break

          if i == imax:
            print(f'Maximum achieved, quitting the loop')
            break

          if not pv:
            break

          pv.click()

          time.sleep(4) 
          print(f'Click {i}')
          i += 1

        return self
 
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
