
import os
import re
import sys

def split_n_trim(txt=''):
  txt_n = txt.split('\n')
  txt_n = list(map(lambda x: x.strip(),txt_n))
  txt_n = list(filter(lambda x: len(x) > 0,txt_n))

  return txt_n
