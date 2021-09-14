
from cmd import Cmd

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

   def do_fetch(self,inp):
     '''fetch URL'''
     drv = self.fbs.driver
     drv.get(inp)

   def do_py(self,inp):
     '''evaluate python code:
          instances:
            shell  - ShellFBS
            fbs    - FBS
            fbpost - FbPost
            drv    - Driver
     '''
     try:
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

   do_EOF = do_quit
   help_EOF = help_quit

