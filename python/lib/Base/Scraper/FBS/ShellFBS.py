
from cmd import Cmd

class ShellFBS(Cmd):
   def __init__(self, args={}):
    super().__init__()

    for k, v in args.items():
      setattr(self, k, v)

   def do_exit(self, inp):
        '''exit the application.'''
        print("Bye")
        return True
 
   def do_add(self, inp):
        print("Adding '{}'".format(inp))
 
   def help_add(self):
       print("Add a new entry to the system.")

   do_EOF = do_exit
   help_EOF = help_exit
