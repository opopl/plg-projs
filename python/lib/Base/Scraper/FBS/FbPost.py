
from dict_recursive_update import recursive_update

from selenium import webdriver

from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException

import xml.etree.ElementTree as et
from lxml import etree
import lxml.html

from io import StringIO, BytesIO

from Base.Core import CoreClass
import Base.Util as util

from Base.Scraper.WebDoc import WebDoc
from Base.Scraper.FBS.WelMan import WelMan

from Base.Mix.mixFileSys import mixFileSys

import time
import os,sys,re

import json
import requests

import shutil

from PIL import Image
from PIL import UnidentifiedImageError

from Base.Scraper.PicBase import PicBase

import base64
import hashlib

from Base.Mix.mixLg import mixLg
from Base.Mix.mixEval import mixEval
from Base.Mix.mixDrv import mixDrv

from copy import copy

class FbPost(
     CoreClass,
     mixFileSys,
     mixLg,
     mixDrv,
     mixEval,
  ):
  # mobile url, TEXT
  url_m = ''

  # url, TEXT
  url = ''

  tags      = ''
  date      = ''
  title     = ''
  ii        = ''
  author_id = ''

  # story text, TEXT
  story = ''

  # current comment
  cmt = {}

  email = None
  password = None

  done = {
    'authorize' : False,
  }

  # xml.etree.ElementTree instance
  ettree = None

  # comments list, ARRAY
  clist = []

  # total number of comments, including sub-comments 
  #     not-equal to len(clist)
  ccount = 0

  # number of pictures
  piccount = 0

  def __init__(self,args={}):
    CoreClass.__init__(self,args)

    if not self.email:
      self.email = os.environ.get('FB_LOGIN')

    if not self.password:
      self.password = os.environ.get('FB_PASS')

    self.init()

  def check_db_projs(self):
    return self

  def check_db_pages(self):
    return self

  def init(self):
    acts = [
      # mixLg
      'init_lg',
      'init_dirs',
      'init_files',
      'init_url',
      'init_driver',
      'check_db_projs',
      'check_db_pages',
    ]

    util.call(self,acts)

    return self

  def init_driver(self):
    app = self.app
    drv = app.driver
    if not drv:
      app.drv_init()

    return self

  def login_send(self):
    if not self.email and self.password:
      self.lge('login_send - no email and password given')
      return self

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

    return self

  def goto_login(self):
    url = util.get(self, 'config.funcs.login.url')
    if not url:
      self.lge('[login] no url')
      return self

    acts = [
      [ 'drv_get', [ url ]],
      [ 'drv_wait', [ { 'id' : 'm_login_email' } ]],
    ]
    
    util.call(self,acts)  

    return self

  def authorize(self):
    if self.done['authorize']:
      return self

    self.goto_login()

    fc = self._file('cookies')
    if not os.path.isfile(fc):
      self.login_send()
      
      self.drv_save_cookies(file=fc)
      return self

    self.drv_load_cookies(file=fc)

    self.done['authorize'] = True

    return self

  def init_dirs(self):

    cwd = os.getcwd()
    self.dirs.update({ 
      'out' : os.path.join(cwd,'out'),
    })

    if self.author_id and self.date and self.ii:
      self.dirs.update({ 
        'out_post' : self._dir('out',[ self.author_id, self.date, self.ii ])
      })

      self.dirs.update({ 
        'out_post_pics_bare' : self._dir('out_post','pics bare'),
        'out_post_pics_save' : self._dir('out_post','pics save'),
      })

      self.mk_dirs()

    return self

  def init_files(self):

    self.files.update({ 
      'post_json' : self._dir('out_post','p.json'),
      'post_html' : self._dir('out_post','p.html'),
      'post_tex'  : self._dir('out_post','p.tex'),
    })

    return self

  def init_url(self):

    if self.url:
      u = util.url_parse(self.url)
  
      m = re.match(r'.*facebook.com$',u['host'])
  
      if m:
        self.url_m = util.url_join('https://mobile.facebook.com',u['path'])

    return self

  def dict_json(self, ref={}):

    exclude = util.qw('dirs files in_dir')
    include = [
      'author_id',
      'ccount',
      'clist',
      'cmt',
      'date',
      'ii',
      'piccount',
      'story',
      'tags',
      'title',
      'url',
      'url_m',
    ]
    d = CoreClass.dict(self,{ 'include' : include })

    return d

  def _html(self, ref={}):
    app = self.app
    drv = app.driver
    src = drv.page_source

    xpath = ref.get('xpath','')

    try:
      self.html2tree()
  
      xel = self.xroot
      src = lxml.html.tostring(xel,pretty_print=True,encoding='unicode')
    except:
      self.lge('[_html]',exc_info=True)

    return src

  '''
    Purpose
      Retrieve list of comments

    Usage
      input: single web element
        clist = self._clist({ 'wel'  : wel })

      input: list of Web elements
        clist = self._clist({ 'wels' : wels })

      options
        'root' - root element

          clist = self._clist({ ... 'opts' : 'root' })

    Return
      ARRAY
  '''
  def _clist(self, ref={}):

    app = self.app

    wel_in = ref.get('wel') or app.driver

    wm_in = WelMan(wel_in)

    wels_comment = ref.get('wels') or wm_in.find_comments()

    opts_s  = ref.get('opts','')
    opts    = opts_s.split(',')

    is_root = ( 'root' in opts )
    if is_root:
      self.ccount = 0
      self.piccount = 0

    clist = []

    if not wels_comment:
      return clist

    for wel_comment in wels_comment:
      self.cmt = {}

      wm_comment = WelMan(wel_comment)

      #cmt['src'] = app._el_src({ 'el' : comment })

      wel_reply = wm_comment.find_reply()
      if wel_reply:
        if app._cfg('driver.click.do'):
          print('Reply click')
          try:
            wel_reply.click()
          except:
            self.save_wf()
            print('[fbPost][_clist] ERROR: Reply click')
            return clist

        time.sleep(1)

        xp = '''.//div[
                    contains(@data-sigil,"inline-reply")
                      and
                    contains(@data-sigil,"comment")
               ]'''
        wels_reply_inline = wm_comment.find({ 'xpath' : xp })

        if len(wels_reply_inline):
          print('Found more replies')
          clist_sub = self._clist({ 'wels' : wels_reply_inline })

          if len(clist_sub):
            print(f'cmt <- {len(clist_sub)} replies')
            self.cmt['clist'] = clist_sub

###cmt_process
      wel_auth = wm_comment.find_one({ 'xpath' : './/div[contains(@class,"_2b05")]' })
      if wel_auth:
        wm_auth = WelMan(wel_auth)

        self.cmt['auth_bare'] = wel_auth.text

        wel_auth_link = wm_auth.find_one({ 'xpath' : './/a' })
        if wel_auth_link:
          href = wel_auth_link.get_attribute('href')
          if href:
            u = util.url_parse(href,{ 'rm_query' : 1 })
            q = u['query']
            qp = util.url_parse_query(q)

            auth_url_path = u['path']
            if u['path'] == '/profile.php':
              if 'id' in qp:
                id = qp.get('id')
                auth_url_path = u['path'] + '?id=' + id

            self.cmt['auth_url_path'] = auth_url_path
            self.cmt['auth_url']      = util.url_join('https://www.facebook.com', auth_url_path)

      wel_txt = wm_comment.find_one({ 
        'xpath' : './/*[@data-sigil="comment-body"]',
      })

      if wel_txt:
        self.cmt['txt']     = wel_txt.text
        #cmt['txt_src'] = app._el_src({ 'el' : el_txt })

      self.cmt_process_attachment({
        'wel' : wel_comment
      })

      if len(self.cmt):
        clist.append(copy(self.cmt))
        self.ccount += 1

    return clist

  def cmt_process_attachment(self,ref={}):
    app = self.app

    wel_in = ref.get('wel')
    wm_in = WelMan(wel_in)

    wel_attach = wm_in.find_one({
      'css' : '.attachment'
    })
    if not wel_attach:
      return self

    wm_attach = WelMan(wel_attach)

    print('Found attachment')

    wel_attach_i = wm_attach.find_one({
      'xpath' : './/i[contains(@class,"img")]',
    })

    if wel_attach_i:
      print('Found image in attachment')
      data_store_attr = wel_attach_i.get_attribute('data-store')
      if data_store_attr:
        data_store = None
        if type(data_store_attr) in [str]:
          try:
            data_store = json.loads(data_store_attr)
          except:
            pass

        if data_store:
          pic_url = data_store.get('imgsrc','')
          print(f'Picture url: {pic_url}')
          if pic_url:
            self.cmt['pic'] = pic_url

            r = {
              'url'        : pic_url,
              'url_parent' : self.url,
              'tags'       : self.tags,
            }
            self.pic = PicBase(r)
            self.pic.grab()

            if self.pic.new_saved:
              self.piccount += 1

    return self

  def _clist2tex(self,ref={}):
    app = self.app

    clist = ref.get('clist') or self.clist

    tex = []
    if clist and len(clist):
      tex.append('\\begin{itemize}')

      for cmt in clist:
        tex_cmt = self._cmt2tex({ 'cmt' : cmt })
        tex.extend(tex_cmt)

      tex.append('\\end{itemize}')

    return tex

  def _cmt2tex(self,ref={}):
    app = self.app

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

  def save_story(self,ref={}):
    app = self.app

    wel_in = ref.get('wel') or app.driver
    wm_in = WelMan(wel_in)

    story = None
    try:
      wel_story = wm_in.find_one({ 'css' : '.story_body_container' })
    except:
      print('ERROR: could not find story!')
      pass

    if not wel_story:
      return self

    wm_story = WelMan(wel_story)

    story_txt = wel_story.text
    story_src = wm_story.src() 

    self.set({
        'story' : {
          'txt' : story_txt,
        }
    })
    
    return self

  def html2tree(self,ref={}):
    app = self.app
    drv = app.driver
    src = drv.page_source
    try:
      self.xtree = lxml.html.parse(StringIO(drv.page_source))
      self.xroot = self.xtree.getroot()

      app.xtree = self.xtree
      app.xroot = self.xroot
    except:
      self.lge('[html2tree] Fail to parse page via lxml.html')

    return self

  def get_url(self,ref={}):
    app = self.app

    url = ref.get('url',self.url_m)

    self.lgi(f'get_url {url}')

    app.drv_get(url)
    time.sleep(5) 

    #self.driver.get('https://mobile.facebook.com/nitsoi.larysa/posts/938801726686200')
    #self.driver.get('https://mobilefacebook.com/olesia.medvedieva/posts/1637472103110572')
    return self

  def save_comments(self,ref={}):
    app = self.app

    clist = self._clist({ 
      'opts' : 'root' 
    })

    self.set({
      'clist' : clist,
    })

    m = [ 
       f'Total Comment Count: {self.ccount}',
       f'Total Picture Count: {self.piccount}'
    ]
    self.lgi(m)

    return self

  def loop_prev(self,ref={}):
    app = self.app

    print('[FbPost][loop_prev] start')

    pv = None

    i    = 1

    imax = self.get('config.funcs.loop_prev.imax') or 10
    imax = ref.get('imax') or imax

    ccc = 0
    ccc_prev = -1
    while 1:
      if i == imax:
        print(f'Maximum achieved, quitting the loop')
        break

      try:
        pv = app._el_find({
          'xpath' : '//*[ starts-with(@id,"see_prev_") ]',
        })
      except:
        break

      if not pv:
        break

      if app._cfg('driver.click.do'):
        try:
          pv.click()

          time.sleep(7) 
          print(f'Click {i}')
        except:
          print('[FbPost][loop_prev] ERROR: pv.click()')

      comments = app._els_comments()
      ccc_prev = ccc
      ccc = len(list(comments))
      print(f'Number of comments: {ccc}, previous: {ccc_prev}')

      if ccc_prev == ccc:
        print(f'BREAK: No new Comments!')

      i += 1

    return self

  def save_wf(self,ref={}):
    app = self.app

    acts = [
       'wf_json'       ,
       'wf_tex'        ,
       'wf_html'       ,
    ]

    util.call(self,acts)

    return self

  def save(self,ref={}):
    app = self.app

    acts = [
       'save_story'    ,
       'save_comments' ,
       'save_wf' ,
    ]

    util.call(self,acts)

    return self

  def process(self,ref={}):
    app = self.app

    acts = [
      'authorize', 
      'get_url', 
      'html2tree', 
      #[ 'loop_prev', [ { 'imax' : 50 } ] ],
      'save',
    ]

    util.call(self,acts)

    return self

  def wf_json(self,ref={}):
    self.lgi('wf_json')

    app = self.app

    data = ref.get('data') or self.dict_json()

    #data_js = json.dumps(data,ensure_ascii=False).encode('utf8')

    try:
      with open(self._file('post_json'), 'w', encoding='utf8') as f:
        json.dump(data, f, ensure_ascii=False)
    except:
      self.lge('json dump')

    import pdb; pdb.set_trace()

    #with open(self.f_json, 'w') as f:
      #f.write(clist_js)

    return self

  def wf_html(self,ref={}):
    self.lgi('wf_html')

    app = self.app

    html = app.driver.page_source
    with open(self._file('post_html'), 'w', encoding='utf8' ) as f:
      f.write(html)

    return self

  def wf_tex(self,ref={}):
    self.lgi('wf_tex')

    app = self.app

    data = ref.get('data') or self.dict()

    clist = self.clist

    tex = []
    tex_clist = self._clist2tex({ 'clist' : clist })

    tex_story = util.get(self, 'story.txt', '')

    tex.extend(app._tex_preamble())
    tex.extend(['\\begin{document}'])
    tex.append(tex_story)
    tex.extend(['\\section{Comments}'])
    tex.extend(tex_clist)
    tex.extend(['\\end{document}'])

    texj = "\n".join(tex)

    with open(self._file('post_tex'), 'w', encoding='utf8') as f:
      f.write(texj)

    return self


