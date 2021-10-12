
import logging
import os

import Base.Util as util

from dict_recursive_update import recursive_update

class mixLg:
  loggers = {}

  def init_lg(self,path='config.logging',lg_conf=None):
    #https://docs.python.org/3/howto/logging-cookbook.html

    # get() from CoreClass
    if not lg_conf:
      lg_conf = self.get(path)
    # lgi - dict with logger configuration
    # lg - logger instance from logging module
    #if type(self).__name__ == 'FbPost':

    #lg_conf = util.call(self,'_eval',[ lg_conf ])

    # formatter
    lg_fmt = lg_conf.get('formatter')
    formatter = logging.Formatter(lg_fmt) if lg_fmt else None

    # loggers
    loggers = lg_conf.get('loggers',[])
    #loggers = util.call(self,'_eval',[ loggers ])

    lfile = lg_conf.get('file')

    if lfile:
      if os.path.isfile(lfile):
        os.remove(lfile)

    for lgi in loggers:
      name  = lgi.get('name')
      level = lgi.get('level')

      if not name and level:
        continue

      lv = util.get(logging,level)

      lg = logging.getLogger(name)
      lg.setLevel(lv)

      handlers = lgi.get('handlers',[])
      for h in handlers:
        handler_name  = h.get('handler')
        handler_level = h.get('level')
        handler_args  = h.get('args',[])

        hsub = util.get(logging,handler_name)
        if hsub and callable(hsub):
          handler = hsub(*handler_args)
          if handler_level:
            hlv = util.get(logging,handler_level)
            handler.setLevel(hlv)
          if formatter:
            handler.setFormatter(formatter)

          lg.addHandler(handler)

      self.loggers.update({ name : lg })

    return self

  # return logger instance
  #     lg('driver','info','hello')
  #     lg('driver','info',[ 'a', 'b', 'c' ])
  def lg(self,name='',lev='',msg=[],**args):
    lg = util.get(self,f'loggers.{name}')
    if not lg:
      print(f'[ERR] no logger registered for name = {name}')
      return self

    if type(msg) in [str]:
      msg = [ msg ]

    sub = util.get(lg,lev)
    if sub and callable(sub):
      for m in msg:
        sub(m,**args)

    return self

  def lgi(self,msg=[],**args):
    lev = 'info'
    name = util.get(self,'config.logging.default.logger','')
    if not name:
      return self

    self.lg(name,lev,msg,**args)
 
    return self

  def lge(self,msg=[],**args):
    lev = 'error'
    name = util.get(self,'config.logging.default.logger','')
    if not name:
      return self

    self.lg(name,lev,msg,exc_info=True,**args)
 
    return self


