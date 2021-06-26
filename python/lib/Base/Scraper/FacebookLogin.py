
from selenium import webdriver

import time
import os
import pickle

import Base.Util as util
import json

LOGIN_URL = 'https://mobile.facebook.com/login.php'

#p [ x['clist'] for x in clist if 'clist' in x and len(x['clist'])]
 
class FacebookLogin():
    email = None
    password = None

    # Firefox profile
    fp = None

    f_cookies = "cookies.pkl"

    f_tex  = "cmt.tex"
    f_json = "cmt.json"

    comment_list = []

    def __init__(self):
        if not self.email:
          self.email = os.environ.get('FB_LOGIN')

        if not self.password:
          self.password = os.environ.get('FB_PASS')


    def init_drv(self):
        fp = webdriver.FirefoxProfile()
        fp.set_preference("dom.webnotifications.enabled",False)
        fp.set_preference("geo.enabled",False)
    
        self.fp = fp
    
        driver = webdriver.Firefox(fp)
        self.driver = driver

        return self

    def main(self):

        acts = [
           [ 'init_drv' ], 
           [ 'get_url_login' ], 
           [ 'load_cookies' ], 
           [ 'get_url_bil' ], 
           [ 'page_loop_prev' ],
           [ 'page_save_comments' ], 
           [ 'page_clist2json' ], 
           [ 'page_clist2tex' ], 
           [ 'save_cookies' ], 
        ] 

        util.call(self,acts)

        return self

    def save_cookies(self):
        print(f'Saving cookie file: {self.f_cookies}')

        pickle.dump( self.driver.get_cookies(), open(self.f_cookies,"wb"))

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

    def get_url_bil(self):
        self.driver.get('https://mobile.facebook.com/yevzhik/posts/3566865556681862')
        return self

    def _el_comments(self,**args):
        el = args.get('el') or self.driver

        cmt_els = None
        try:
          cmt_els = el.find_elements_by_xpath('.//div[ @data-sigil="comment" ]')
        except:
          pass

        return cmt_els

    def _el_reply(self,**args):
        elin = args.get('el') or self.driver

        reply = None
        try:
          reply = elin.find_element_by_xpath('.//div[ @data-sigil="replies-see-more" ]')
        except:
          pass

        return reply

    def page_save_comments(self,**args):

        clist = self._page_clist()
        self.comment_list = clist

        return self

    def _clist2tex(self,**args):
        clist = args.get('clist') or self.comment_list

        tex = []
        tex.append('\\begin{itemize}')

        for cmt in clist:
          tex_cmt = self._cmt2tex(cmt=cmt)
          tex.extend(tex_cmt)

        tex.append('\\end{itemize}')

        return tex

    def _cmt2tex(self,**args):
        cmt = args.get('cmt')

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
            tex.extend(self._clist2tex(clist=clist_sub))

        return tex

    def page_clist2json(self,**args):
        clist = args.get('clist') or self.comment_list

        clist_js = json.dumps(clist,ensure_ascii=False).encode('utf8')

        #with open(self.f_json, 'w') as f:
          #f.write(clist_js)

        with open(self.f_json, 'w', encoding='utf8') as f:
          json.dump(clist, f, ensure_ascii=False)

        return self

    def page_clist2tex(self,**args):
        clist = args.get('clist') or self.comment_list

        tex = self._clist2tex(clist=clist)
        texj = "\n".join(tex)

        with open(self.f_tex, 'w') as f:
          f.write(texj)

        return self

    def _page_clist(self,**args):
        '''
          clist = self._page_clist(el=el)
          clist = self._page_clist(els=els)
        '''
        elin = args.get('el') or self.driver

        cmt_els = args.get('els')
        if not cmt_els:
          cmt_els = self._el_comments(el=elin)

        clist = []

        if not cmt_els:
          return clist

        for comment in cmt_els:
          cmt = {}

          reply = self._el_reply(el=comment)
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
              clist_sub = self._page_clist(els=replies_inline)

              if len(clist_sub):
                print(f'cmt <- {len(clist_sub)} replies')
                cmt['clist'] = clist_sub

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

          if len(cmt):
            clist.append(cmt)

        return clist

    def page_loop_prev(self,**args):

        pv = None

        i    = 1
        imax = args.get('imax') or 10

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

          html = self.driver.page_source
          with open(f'{i}.html', 'w') as f:
            f.write(html)

          time.sleep(4) 
          print(f'Click {i}')
          i += 1

        return self
 
    def login(self):
        self.get_login()

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

        pickle.dump( self.driver.get_cookies(), open(self.f_cookies,"wb"))

        return self


