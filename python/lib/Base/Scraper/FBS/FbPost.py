

from selenium import webdriver

from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException

from Base.Core import CoreClass
import Base.Util as util

from Base.Mix.mixFileSys import mixFileSys

import time
import os,sys,re

import json
import requests

import shutil

from PIL import Image
from PIL import UnidentifiedImageError

import base64
import hashlib

from copy import copy

class FbPost(CoreClass,mixFileSys):
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

  # comments list, ARRAY
  clist = []

  # total number of comments, including sub-comments 
  #     not-equal to len(clist)
  ccount = 0

  # number of pictures
  piccount = 0

  def __init__(self,args={}):
    for k, v in args.items():
      setattr(self, k, v)

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

      self.files.update({ 
          'post_json' : self._dir('out_post','p.json'),
          'post_html' : self._dir('out_post','p.html'),
          'post_tex'  : self._dir('out_post','p.tex'),
      })

    if self.url:
      u = util.url_parse(self.url)
  
      m = re.match(r'.*facebook.com$',u['host'])
  
      if m:
        self.url_m = util.url_join('https://mobile.facebook.com',u['path'])

  def dict_json(self, ref={}):

    exclude = util.qw('dirs files in_dir')
    d = CoreClass.dict(self,{ 'exclude' : exclude })

    return d

  def _clist(self, ref={}):
    '''
      Purpose
        Retrieve list of comments

      Usage
        input: single web element
          clist = self._clist({ 'el'  : el })

        input: list of Web elements
          clist = self._clist({ 'els' : els })

        options
          'root' - root element

            clist = self._clist({ ... 'opts' : 'root' })

      Return
        ARRAY
    '''
    app = self.app

    elin = ref.get('el') or app.driver

    cmt_elems = ref.get('els')
    if not cmt_elems:
      cmt_elems = app._els_comments({ 'el' : elin })

    opts_s  = ref.get('opts','')
    opts    = opts_s.split(',')

    is_root = ( 'root' in opts )
    if is_root:
      self.ccount = 0
      self.piccount = 0

    clist = []

    if not cmt_elems:
      return clist

    for comment in cmt_elems:
      self.cmt = {}

      #cmt['src'] = app._el_src({ 'el' : comment })

      reply = app._el_reply({ 'el' : comment })
      if reply:
        print('Reply click')
        try:
          reply.click()
        except:
          self.save_wf()
          print('[fbPost][_clist] ERROR: Reply click')
          return clist

        time.sleep(1)

        replies_inline = None
        try:
          xp = '''.//div[
                    contains(@data-sigil,"inline-reply")
                      and
                    contains(@data-sigil,"comment")
               ]'''
          replies_inline = comment.find_elements_by_xpath(xp)
        except:
          pass

        if replies_inline and len(replies_inline):
          print('Found more replies')
          clist_sub = self._clist({ 'els' : replies_inline })

          if len(clist_sub):
            print(f'cmt <- {len(clist_sub)} replies')
            self.cmt['clist'] = clist_sub

###cmt_process
      el_auth = comment.find_element_by_xpath('.//div[contains(@class,"_2b05")]')
      if el_auth:
        self.cmt['auth_bare'] = el_auth.text

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

            self.cmt['auth_url_path'] = auth_url_path
            self.cmt['auth_url']      = util.url_join('https://www.facebook.com', auth_url_path)

      el_txt = app._el_find({ 
        'el'    : comment,
        'xpath' : './/*[@data-sigil="comment-body"]',
      })

      if el_txt:
        self.cmt['txt']     = el_txt.text
        #cmt['txt_src'] = app._el_src({ 'el' : el_txt })

      self.cmt_process_attachment({
        'el' : comment
      })

      if len(self.cmt):
        clist.append(copy(self.cmt))
        self.ccount += 1

    return clist

  def cmt_process_attachment(self,ref={}):
    app = self.app

    elin = ref.get('el')

    el_attach = app._el_find({
      'el'  : elin,
      'css' : '.attachment'
    })

    if not el_attach:
      return self

    print('Found attachment')

    el_attach_i = app._el_find({
      'el'    : el_attach,
      'xpath' : './/i[contains(@class,"img")]',
    })

    if el_attach_i:
      print('Found image in attachment')
      data_store_attr = el_attach_i.get_attribute('data-store')
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
            self.pic_fetch({ 'url' : pic_url })

    return self

  def pic_fetch(self,ref={}):
    url = ref.get('url','')
    if not url:
      return self

    headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.3'
    }

    args = {
      'headers' : headers,
      'verify'  : False,
      'stream'  : True,
    }
    r = requests.get(pic_url,**args)
    if not ( r.status_code == 200 ):
      return self

    self.piccount += 1
    print(f'Got Picture {self.piccount}')
    r.raw.decoded_content = True
    ct = util.get(r.headers, 'content-type', '')

    pic = {}
    for k in util.qw('i ct bare png'):
      pic[k] = None

    pic['bare'] = self._dir('out_post_pics_bare',f'{self.piccount}')
    pic['png']  = self._dir('out_post_pics_save',f'{self.piccount}.png')

    with open(pic['bare'], 'wb') as lf:
      shutil.copyfileobj(r.raw, lf)

    with open(pic['bare'],"rb") as f:
      b = f.read() # read file as bytes
      pic['md5'] = hashlib.md5(b).hexdigest()

    pic = self._pic_load(pic)

    return self

  def _pic_load(self,pic={}):

    try:
      pic['i'] = Image.open(pic['bare'])
    except UnidentifiedImageError:

      if pic['ct']:
        if pic['ct'] in [ 'image/svg+xml' ]:
          cairosvg.svg2png(
            file_obj = open(pic['bare'], "rb"),
            write_to = pic['png']
          )
          pic['i']= Image.open(pic['png'])

        elif pic['ct'] in [ 'image/gif' ]:
          pass

    if not pic['i']:
      return 

    pic['width']  = pic['i'].width
    pic['height'] = pic['i'].height

    return pic

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

    elin = ref.get('el') or app.driver

    story = None
    try:
      story = elin.find_element_by_css_selector('.story_body_container')
    except:
      print('ERROR: could not find story!')
      pass

    if not story:
      return self

    story_txt = story.text
    story_src = app._el_src({ 'el' : story })

    self.set({
        'story' : {
          'txt' : story_txt,
        }
    })
    
    return self

  def get_url(self,ref={}):
    app = self.app

    print('[FbPost][get_url] start')

    url = ref.get('url',self.url_m)

    app.driver.get(url)
    time.sleep(5) 

    #self.driver.get('https://mobile.facebook.com/nitsoi.larysa/posts/938801726686200')
    #self.driver.get('https://mobilefacebook.com/olesia.medvedieva/posts/1637472103110572')
    return self

  def save_comments(self,ref={}):
    app = self.app

    clist = self._clist({ 'opts' : 'root' })

    self.set({
      'clist' : clist,
    })

    print(f'Total Comment Count: {self.ccount}')
    print(f'Total Picture Count: {self.piccount}')

    return self

  def loop_prev(self,ref={}):
    app = self.app

    print('[FbPost][loop_prev] start')

    pv = None

    i    = 1
    imax = ref.get('imax') or 10

    ccc = 0
    ccc_prev = -1
    while 1:
      try:
        pv = app._el_find({
          'xpath' : '//*[ starts-with(@id,"see_prev_") ]',
        })
      except:
        break

      if i == imax:
        print(f'Maximum achieved, quitting the loop')
        break

      if not pv:
        break

      try:
        pv.click()
      except:
        print('[FbPost][loop_prev] ERROR: pv.click()')
        import pdb; pdb.set_trace()

      time.sleep(7) 
      print(f'Click {i}')

      comments = app._els_comments()
      ccc_prev = ccc
      ccc = len(list(comments))
      print(f'Number of comments: {ccc}, previous: {ccc_prev}')

      if ccc_prev == ccc:
        print(f'BREAK: No new Comments!')
        import pdb; pdb.set_trace()

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
      'get_url', 
      [ 'loop_prev', [ { 'imax' : 50 } ] ],
      'save',
    ]

    util.call(self,acts)

    return self

  def wf_json(self,ref={}):
    app = self.app

    data = ref.get('data') or self.dict_json()

    #data_js = json.dumps(data,ensure_ascii=False).encode('utf8')

    try:
      with open(self._file('post_json'), 'w', encoding='utf8') as f:
        json.dump(data, f, ensure_ascii=False)
    except:
      print('ERROR: json dump')
      import pdb; pdb.set_trace()

    #with open(self.f_json, 'w') as f:
      #f.write(clist_js)

    return self

  def wf_html(self,ref={}):
    app = self.app

    html = app.driver.page_source
    with open(self._file('post_html'), 'w', encoding='utf8' ) as f:
      f.write(html)

    return self

  def wf_tex(self,ref={}):
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


