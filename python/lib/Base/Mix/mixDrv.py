
import Base.Util as util

from selenium.webdriver.support import ui
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By

from seleniumwire import webdriver as webDriverWire
from selenium import webdriver as webDriver

class mixDrv:

  # browser (Firefox) driver
  driver = None

  def drv_get(self,url):
    if not (self.driver and url):
      return self

    try:
      self.driver.get(url)
    except:
      self.lg('driver','error',f' driver.get(url), url = {url}',exc_info=True)

    return self

  def drv_wait(self,r_wait={}):
    if not len(r_wait):
      return self

    elem = None

    # mixEval
    r_wait = self._eval_all(r_wait)

    w_xpath = r_wait.get('xpath','')

    w_frame = r_wait.get('frame','')

    w_xpath_list = []
    if type(w_xpath) in [str]:
      if w_xpath:
        w_xpath_list = [ w_xpath ]
    elif type(w_xpath) in [list]:
      w_xpath_list = w_xpath

    r_url   = r_wait.get('url',{})

    w_url_path = None; w_url = None

    if type(r_url) in [dict]:
      w_url_path = r_url.get('path','')
    elif type(r_url) in [str]:
      w_url = r_url

    cond_keys = [ 
      'text.contains' 
    ]

    def _wait_condition(drv):
      ok = 1

      msgs = { 'ok' : [], 'fail' : [] }

      elem = None; elem_txt = None

      if len(w_xpath_list):
        for w_xpath in w_xpath_list:
          elem = drv.find_element_by_xpath(w_xpath)
          if elem:
            elem_txt = util.get(elem,'text') or ''
  
          ok = ok and elem
          if ok:
            msg = f'driver_wait OK: xpath => {w_xpath}'
            msgs.get('ok').append(msg)
          else:
            return False

      for k in cond_keys:
        vv = util.get(r_wait,k) or ''
        if vv in [None, '']:
          continue
        if k == 'text.contains':
          ok = ok and elem_txt
          if elem_txt:
            ok = ok and (vv in elem_txt)
            if ok:
              msg = f'driver_wait OK: text.contains => {vv}'
              msgs.get('ok').append(msg)

        if not ok:
          return False

      #if w_url_path == '/checkout/confirm.tmpl':
        #import pdb; pdb.set_trace()

      if w_url_path:
        ok = ok and ( self._cu('path') == w_url_path )
        if ok:
          msg = f'driver_wait OK: url.path => {w_url_path}'
          msgs.get('ok').append(msg)

      if ok:
        for msg in msgs.get('ok'):
          self.lg('driver','info',msg)

      return ok

    timeout = self._get('config.selenium.WebDriverWait.timeout',10)
    if w_frame:
      self.drv_switch(w_frame)

    try:
      self.lg('driver','info',f'driver_wait timeout={timeout}, waiting: {r_wait}')
      wait_res = WebDriverWait(self.driver, timeout).until( _wait_condition )
    except:
      self.lg('driver','error',"driver_wait errors", exc_info=True)
      if util.get(self,'exceptions.dbg'): 
        import pdb; pdb.set_trace()
    finally:
      self.drv_switch_back()

    return self

