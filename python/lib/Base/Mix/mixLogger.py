
import Base.DBW as dbw
import Base.Util as util

class mixLogger:

  def die(self,msg='',opts = {}):
    self.log(msg)

    if opts.get('on_fail',1):
      self.on_fail()

    if not self._opt('no_die'):
      raise Exception(msg)    

    return self

  def log_short(self,msg=[]):
    self.log(msg,{ 'log_ids' : 'log_short' })
    return self

  def log(self,msg=[],opts={}):
    if type(msg) is list:
      for m in msg:
        self.log(m)
      return self
  
    if not type(msg) is str:
      return self
      
    self.log_db(msg)

    log_ids = util.qw('log')
    log_ids_in = opts.get('log_ids',log_ids) 
    if type(log_ids_in) is str:
      log_ids = util.qw(log_ids_in)

    print(msg)

    for lid in log_ids:
      f_log = self._file(lid)
      if f_log:
        with open(f_log, 'a') as f:
          f.write(msg + '\n')
    
    return self

  def log_db(self,msg=[]):
    if type(msg) is list:
      for m in msg:
        self.log(m)
      return self
  
    if not type(msg) is str:
      return self

    db_file = self.dbfile.pages

    tables = [ 'log' ]
    for table in tables:
      exist = dbw._tb_exist({ 
        'table'   : table,
        'db_file' : db_file,
      })
      
      if not exist:
        continue
    
      insert = {
          'msg'   : msg,
          'rid'   : self.page.rid,
          'url'   : self.page.url,
          'site'  : self.page.site,
          'time'  : util.now()
      }
    
      d = {
         'db_file' : self.dbfile.pages,
         'table'   : table,
         'insert'  : insert,
      }
      dbw.insert_dict(d)

    return self

