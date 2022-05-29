
import os,re,sys

import Base.DBW as dbw
import Base.Util as util

import Base.Rgx as rgx

class secReader:
  # current line within a loop
  line = None

  # lines loaded from section file
  lines = []

  def ln_shift(self):
    if not len(self.lines):
      self.flags['eof'] = 1
      return self

    self.line = self.lines.pop(0)
    self.line = self.line.strip('\n')

    return self

  def ln_match_head(self):
    if self.flags['eof']:
      return self

    if rgx.match('tex.projs.beginhead', self.line):
      self.flags['head'] = 1
      self.sec_data['save']['beginhead'] = self.line
      self.ln_shift()

    if rgx.match('tex.projs.endhead', self.line):
      self.sec_data['save']['endhead'] = self.line
      if 'head' in self.flags:
        del self.flags['head']
      self.ln_shift()

      self.flags['head_done'] = 1
      self.flags['body'] = 1

    return self

  def ln_match_purl(self):
    ok = 1
    ok = ok and not self.flags.get('eof')
    ok = ok and not self.flags.get('securl')
    if not ok:
      return self

    m = rgx.match('tex.projs.body.purl', self.line)
    if not m:
      return self

    self.flags['securl'] = 1

    self.sec_data['securl'] = m.group(1)

    return self

  def ln_match_seccmd(self):
    ok = 1
    ok = ok and not self.flags.get('eof')
    ok = ok and not self.flags.get('seccmd')
    if not ok:
      return self

    m = rgx.match('tex.projs.seccmd', self.line)

    if not m:
      return self

    self.flags['seccmd'] = 1

    self.sec_data['seccmd']   = m.group(1)
    self.sec_data['sectitle'] = m.group(2)

    return self

