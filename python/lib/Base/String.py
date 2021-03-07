
import os
import re
import sys

import Base.Const as const

def split_trim_uniq(txt='',**kwargs):
  pass

def split_n_trim(txt='',sep='\n'):
  txt_n = txt.split('\n')
  txt_n = list(map(lambda x: x.strip(),txt_n))
  txt_n = list(filter(lambda x: len(x) > 0,txt_n))

  return txt_n

def strip_n(txt='', opts = {}):
  txt_n = txt.split('\n')
  txt_n = list(map(lambda x: x.strip(),txt_n))
  txt_n = list(filter(lambda x: len(x) > 0,txt_n))
  txt = ''.join(txt_n)

  return txt

def strip_nq(txt='', opts = {}):
  txt = strip_n(txt)
  for q in [const.q, const.qq]:
    txt = re.sub(rf'^{q}(.*){q}$', '\1', txt)
  return txt
