
from cmd import Cmd
import xml.etree.ElementTree as ET

import time
import os,sys,re

import Base.Util as util

class ShellFBS(Cmd):
   fbs = None

   prompt = 'FBS> '

   def __init__(self, args={}):
     super().__init__()
 
     for k, v in args.items():
       setattr(self, k, v)

   def do_q(self,inp):
     return self.do_quit(inp)

   def do_h(self,inp):
     self.do_help(inp)

   def do_quit(self,inp):
     '''exit the application'''
     print("Bye")
     return True

   def do_fetch(self,url):
     '''fetch URL'''
     drv = self.fbs.driver
     if not drv:
       print('[fetch] no driver!')
       return 

     if not url:
       print('[fetch] no url!')
       return 

     try:
       drv.get(url)
     except:
       print(f'[fetch] drv.get: {url}')
       ei = sys.exc_info()
       print(f'{ei}')

   def _globs(self):
     fbs = self.fbs
     globs = { 
       'shell' : self,
       'fbs'   : fbs,
     }

     if hasattr(fbs,'driver') and fbs.driver:
       globs.update({ 'drv' : fbs.driver })

     if hasattr(fbs,'post') and fbs.post:
       globs.update({ 'fbpost' : fbs.post })

     return globs

   def do_x(self,inp):
     if not inp:
       print('[x] no input!')
       return 

     fbs = self.fbs
     try:
       globs = self._globs()
       globs.update(globals())

       #print(inp)
       #print(f'do_x, globs = {list(globs.keys())}')

       result = util.x(inp,globs)
       print(result)
     except NameError as e:
       print(e)
     except UnboundLocalError as e:
       print(e)

     except:
       ei = sys.exc_info()
       print(f'fail: {ei[0]}')

   def do_xpath_rm(self,xpath):
     if not xpath:
       print('[xpath_rm] no xpath!')
       return 

     fbs = self.fbs
     etree = fbs.etree
     xtree = fbs.xtree

     try:
       elems = fbs.xtree.xpath(xpath)
       for elem in elems:
         parent = elem.getparent()
         if parent is not None:
           parent.remove(elem)
     except:
       e = sys.exc_info()
       print(f'[xpath_rm]: {e}')

   def do_xpath(self,xpath):
     if not xpath:
       print('[xpath] no xpath!')
       return 

     out = []

     fbs = self.fbs
     # lxml.etree
     etree = fbs.etree

     # page tree
     #xtree = fbs.xtree

     try:
       elems = fbs.xtree.xpath(xpath)
       for elem in elems:
         txt = None
         n = type(elem).__name__
         if n == 'HtmlElement':
           txt = fbs.etree.tostring(elem,encoding='unicode',pretty_print=True)
         elif n == '_ElementUnicodeResult':
           txt = elem.__str__()
         out.append(txt)
     except:
       fbs.lg('fbs','error',f'xpath: {xpath}',exc_info=True)

     for ln in out:
       print(ln)

   def do_page_print(self,inp):
     '''print current page source
     '''
     fbs = self.fbs
     drv = self.fbs.driver
     src = drv.page_source

     print(src)

   def do_run(self,inp):
     '''run FBS'''
     fbs = self.fbs
     if fbs:
       fbs.do_shell = False
       fbs.c_run()

   def do_cd(self,dir):
     if dir:
       if os.path.isdir(dir):
         os.chdir(dir)
         self.do_pwd()

   def do_pwd(self,dir):
     pwd = os.getcwd()
     print(pwd)

   def do_pdb(self,inp):
     print("Starting Python Debugger...")
     import pdb; pdb.set_trace()

   def do_driver_init(self,inp):
     ok = 0
     try:
       self.fbs.init_drv()
       ok = 1
     except:
       e = sys.exc_info()
       print(f'[driver_init] fail: {e}')

   def do_add(self, inp):
     print("Adding '{}'".format(inp))

   def help_q(self):
     self.help_quit()

   def help_quit(self):
     print("exit.")
 
   def help_add(self):
     print("Add a new entry to the system")

   def help_x(self):
     msg_a = [
        'evaluate python code:',
        '  instances:',
        ' ',
        'shell  - ShellFBS',
     ]

     msg = '\n'.join(msg_a)
     print(msg)

   do_EOF = do_quit
   help_EOF = help_quit

