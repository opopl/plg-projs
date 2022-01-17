
import os
import re
import sys

import Base.Const as const
import Base.Util as util

def explode(txt='',**kwargs):
  sep = kwargs.get('sep','\n')

  txt_a = txt.split(sep)

  return txt_a

def char_range(start, end, step=1):
  for char in range(ord(start), ord(end)+1, step):
    yield chr(char)

def join(sep='',arr=[]):
  arr = list(map(lambda x: str(x), arr))
  s = sep.join(arr)
  return s

def ids_merge(ids_in = []):
  ids_merged = []
  for id in ids_in:
    ids = split_n_trim(id, sep = ',')
    ids_merged.extend(ids)

  ids_merged = util.uniq(ids_merged)
  ids_merged_s = ','.join(ids_merged)

  return ids_merged_s

def ids_remove(ids_in = [], ids_remove = []):

  ids_in_a     = []
  ids_remove_a = []

  ids_new_a    = []

  for id in ids_in:
    ids = split_n_trim(id, sep = ',')
    ids_in_a.extend(ids)

  for id in ids_remove:
    ids = split_n_trim(id, sep = ',')
    ids_remove_a.extend(ids)

  for id in ids_in_a:
    if not id in ids_remove_a:
      ids_new_a.append(id)

  ids_new_a = util.uniq(ids_new_a)
  ids_new   = ','.join(ids_new_a)

  return ids_new


def split_n_trim(txt='',sep='\n'):
  txt_n = txt.split(sep)
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
