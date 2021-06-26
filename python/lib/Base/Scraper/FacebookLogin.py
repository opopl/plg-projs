
from selenium import webdriver

import time
import os
import pickle

import Base.Util as util

LOGIN_URL = 'https://mobile.facebook.com/login.php'
 
class FacebookLogin():
    email = None
    password = None

    # Firefox profile
    fp = None

    f_cookies = "cookies.pkl"

    comments = []

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
           [ 'page_save_comments' ], 
           #[ 'page_loop_prev' ], 
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

    def page_save_comments(self):

        cmt_els = self.driver.find_elements_by_xpath('.//div[ @data-sigil="comment" ]')
        for el in cmt_els:
          cmt = {}

          el_auth = el.find_element_by_xpath('.//div[@class="_2b05"]')
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

          el_txt = el.find_element_by_xpath('.//*[@data-sigil="comment-body"]')
          if el_txt:
            cmt['txt'] = el_txt.text

          if len(cmt):
            self.comments.append(cmt)

          import pdb; pdb.set_trace()

        return self

    def page_loop_prev(self):

        i = 1
        pv = None
        imax = 10
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


