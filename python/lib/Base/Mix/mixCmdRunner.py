
import Base.Util as util

class mixCmdRunner:

  def do_cmd(self,cmds=None):
    if not cmds:
      cmds = util.get(self,'vars.mixCmdRunner.cmds',[])

    for cmd in cmds:
      sub = f'c_{cmd}'
      if not util.obj_has_method(self,sub):
        print(f'No method: {sub}')
        continue

      util.call(self, sub)
  
    return self
