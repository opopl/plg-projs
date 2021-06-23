
import getopt,argparse,sys

import Base.Util as util

class mixGetOpt:

  skip_get_opt = False

  #command-line options
  oa = None

  def get_opt(self,ref={}):
    '''
      usage:
          use class fields self.opts_argparse, self.usage
        self.get_opt()
  
          opts - ARRAY of options
        self.get_opt({ 'opts' : opts })
  
          usage - STRING
        self.get_opt({ 'opts' : opts, 'usage' : usage })
    '''
    if self.skip_get_opt:
      return self

    opts  = util.get(self,'opts_argparse',[])
    opts  = ref.get('opts',opts)

    usage = util.get(self,'usage','')
    usage = ref.get('usage',usage)

    self.parser = argparse.ArgumentParser(usage=usage)

    for opt in opts:
      arr  = opt.get('arr',[])
      kwd  = opt.get('kwd',{})

      if not len(arr):
        continue
      
      if type(arr) in [str]:
        arr = util.qw(arr)

      self.parser.add_argument(*arr, **kwd)

    self.oa = self.parser.parse_args()

    if len(sys.argv) == 1:
      self.parser.print_help()
      sys.exit()

    cmd_s = util.get(self,'oa.cmd')
    if not cmd_s:
      print('No command provided!')
      exit(0)

    cmds = cmd_s.split(',')
    self.vars['mixCmdRunner']['cmds'].extend(cmds)

    return self
