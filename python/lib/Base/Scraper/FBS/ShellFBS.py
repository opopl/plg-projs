
from cmd import Cmd

class ShellFBS(Cmd):
   fbs = None

   def __init__(self, args={}):
    super().__init__()

    for k, v in args.items():
      setattr(self, k, v)

   def do_exit(self, inp):
        '''exit the application.'''
        print("Bye")
        return True

   def do_fbs_run(self, inp):
        '''run FBS'''
        fbs = self.fbs
        if fbs:
          fbs.do_shell = False
          fbs.main()
 
   def do_add(self, inp):
        print("Adding '{}'".format(inp))
 
   def help_add(self):
       print("Add a new entry to the system.")

   def help_exit(self):
       print("exit.")

   do_EOF = do_exit
   help_EOF = help_exit

