

from selenium import webdriver

from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException

from Base.Core import CoreClass
import Base.Util as util

import time
import os,sys,re

import json
import requests

class FbPost(CoreClass):
  # mobile url, TEXT
  url_m = ''

  # url, TEXT
  url = ''

  tags  = ''
  date  = ''
  title = ''

  # story text, TEXT
  story = ''

  # comments list, ARRAY
  clist = []

  # total number of comments, including sub-comments 
  #     not-equal to len(clist)
  ccount = 0

  def __init__(self,args={}):
    for k, v in args.items():
      setattr(self, k, v)

    if self.url:
      u = util.url_parse(self.url)
  
      m = re.match(r'.*facebook.com$',u['host'])
  
      if m:
        self.url_m = util.url_join('https://mobile.facebook.com',u['path'])

  def dict_json(self, ref={}):

    exclude = util.qw('f_json f_html f_tex')
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

    opts_s = ref.get('opts','')
    opts = opts_s.split(',')
    is_root = ( 'root' in opts ) 
    if is_root:
      self.ccount = 0

    clist = []

    if not cmt_elems:
      return clist

    for comment in cmt_elems:
      cmt = {}

      cmt['src'] = app._el_src({ 'el' : comment })

      reply = app._el_reply({ 'el' : comment })
      if reply:
        print('Reply click')
        reply.click()
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
            cmt['clist'] = clist_sub

###cmt_process
      el_auth = comment.find_element_by_xpath('.//div[contains(@class,"_2b05")]')
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

      el_txt = app._el_find({ 
        'el'    : comment,
        'xpath' : './/*[@data-sigil="comment-body"]',
      })

      if el_txt:
        cmt['txt']     = el_txt.text
        cmt['txt_src'] = app._el_src({ 'el' : el_txt })

      el_attach = app._el_find({ 
        'el'  : comment,
        'css' : '.attachment'
      })

      if el_attach:
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
                cmt['pic'] = pic_url

                headers = {
                 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.3'
                }

                args = {
                  'headers' : headers,
                  'verify'  : False,
                  'stream'  : True,
                }
                r = requests.get(pic_url,**args)
                import pdb; pdb.set_trace()
                #if r:
                  #r.raw.decoded_content = True
                  #ct = util.get(r.headers, 'content-type', '')
              
                  #with open(pic.tmp['bare'], 'wb') as lf:
                    #shutil.copyfileobj(r.raw, lf)

      if len(cmt):
        clist.append(cmt)
        self.ccount += 1

    return clist

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
      raise
      pass

    if not story:
      return self

    story_txt = story.text
    story_src = app._el_src({ 'el' : story })

    self.set({
        'story'      : {
          'txt' : story_txt,
          'src' : story_src,
        }
    })
    
    return self

  def get_url(self,ref={}):
    app = self.app

    print('[FbPost][get_url] start')

    url = ref.get('url',self.url_m)

    app.driver.get(url)
    time.sleep(5) 

    # 18.01.2021
    #self.driver.get('https://mobile.facebook.com/yevzhik/posts/3566865556681862')

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

    return self

  def loop_prev(self,ref={}):
    app = self.app

    print('[FbPost][loop_prev] start')

    pv = None

    i    = 1
    imax = ref.get('imax') or 10

    while 1:
      try:
        pv = app.driver.find_element_by_id('see_prev_3566865556681862')
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

  def process(self,ref={}):
    app = self.app

    acts = [
       'get_url', 
      [ 'loop_prev', [ { 'imax' : 70 } ] ],
       'save_story'    ,
       'save_comments' ,
       'wf_json'       ,
       'wf_tex'        ,
       'wf_html'       ,
    ]

    util.call(self,acts)

    return self

  def wf_json(self,ref={}):
    app = self.app

    data = ref.get('data') or self.dict_json()

    #data_js = json.dumps(data,ensure_ascii=False).encode('utf8')

    try:
      with open(self.f_json, 'w', encoding='utf8') as f:
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
    with open(self.f_html, 'w', encoding='utf8' ) as f:
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

    with open(self.f_tex, 'w', encoding='utf8') as f:
      f.write(texj)

    return self


