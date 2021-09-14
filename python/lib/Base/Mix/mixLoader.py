
from pathlib import Path
import yaml

import os,re,sys

from Base.Zlan import Zlan
import Base.Util as util

class mixLoader:
  def load_yaml(self, ref={}):
    f_yaml = util.get(self,'files.yaml')
    f_yaml = ref.get('yaml',f_yaml)

    if f_yaml and os.path.isfile(f_yaml):
      with open(f_yaml) as f:
        d = yaml.full_load(f)
        for k,v in d.items():
          setattr(self,k,v)

    if os.path.isdir(self.in_dir):
      for f in Path(self.in_dir).glob('*.yaml'):
        k = Path(f).stem
        with open(str(f),'r') as y:
          d = yaml.full_load(y)
          setattr(self, k, d)

    return self

###zlan
  def load_zlan(self, ref={}):
    f_zlan = util.get(self,'files.zlan')
    f_zlan = ref.get('zlan',f_zlan)

    if not f_zlan:
      return self

    print(f'[load_zlan] file: {f_zlan}')

    self.zlan = Zlan({
      'file' : f_zlan
    })

    self.zlan.get_data()

    zdata  = self.zlan.data
    zorder = self.zlan.order

    if not self.urldata:
      self.urldata = []

    for k in zdata.keys():
      if k in util.qw('order lines_main lines_eof'):
        continue
        
      url = k
      d = zdata.get(url)
      if not d.get('off'):
        self.urldata.append(d)

    return self

