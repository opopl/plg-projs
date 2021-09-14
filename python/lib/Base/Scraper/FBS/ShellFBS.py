
from cmd import Cmd
import xml.etree.ElementTree as ET

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
     if url:
       try:
         drv.get(url)
       except:
         print(f'fetch fail: {url}')

   def do_x(self,inp):
     fbs = self.fbs
     '''evaluate python code:
          instances:
            shell  - ShellFBS
            fbs    - FBS
            fbpost - FbPost
            drv    - Driver
     '''
     try:
       globs = { 'shell' : self }
       if hasattr(fbs,'post') and fbs.post:

       exec(inp,{
           'shell'  : self,
           'fbs'    : self.fbs,
           'fbpost' : self.fbs.post,
           'drv'    : self.fbs.driver,
       })
     except:
       print('fail')

   def do_page_print(self,inp):
     '''print current page source
     '''
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

   def do_pwd(self,dir):
     pwd = os.getcwd()
     print(pwd)

   def do_pdb(self,inp):
     print("Starting Python Debugger...")
     import pdb; pdb.set_trace()
 
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

