
import os,re,sys

import Base.DBW as dbw
import Base.Util as util

import Base.Rgx as rgx

class secReader:
  # current line within a loop
  line = None

  # lines loaded from section file
  lines = []

  # flags within the loop
  flags = {}

  # current sec data
  sec_info = {
    'top_lines'  : [],
    'body_lines' : [],
    'head_lines' : [],
    'head_keyval'  : {},
    'seccmd'     : '',
    'sectitle'   : '',
    'save' : {
        'beginhead' : '',
        'endhead'   : '',
        'before_seccmd' : [],
        'before_securl' : [],
    }
  }

  def ln_loop(self,ref={}):
    if not self.lines:
      return self

    self.flags = {}
    self.flags['eof'] = 0
    while len(self.lines):
      self.ln_shift()

      self.ln_match_head()
      self.ln_match_seccmd()
      self.ln_match_purl()

      self.ln_if_head()
      self.ln_if_top()
      self.ln_if_body()

    self.sec_info.update({ 'done' : 1 })

    return self

  def sec_info_reset(self,ref={}):
    self.sec_info = {
      # section name
      'sec'  : '',
      # full path sec_file
      'file'  : '',
      # project name
      'proj' : '',
      # section data has been imported into sec_info?
      'done' : 0,
      # lines before head block
      'top_lines' : [],
      # lines after head block
      'body_lines' : [],
      # beginhead ... endhead lines
      'head_lines' : [],
      # keys from head block
      'head_keyval' : {},
      # e.g. subsection
      'seccmd' : '',
      'securl' : '',
      # title inside seccmd command
      'sectitle' : '',
      # all lines
      'all_lines' : [],
      # saved
      'save' : {
        'beginhead' : '',
        'endhead'   : '',
        'before_seccmd' : [],
        'before_securl' : [],
      }
    }
    self.sec_info.update(ref)

    return self


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
      self.sec_info['save']['beginhead'] = self.line
      self.ln_shift()

    if rgx.match('tex.projs.endhead', self.line):
      self.sec_info['save']['endhead'] = self.line
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

    self.sec_info['securl'] = m.group(1)

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

    self.sec_info['seccmd']   = m.group(1)
    self.sec_info['sectitle'] = m.group(2)

    return self

  def ln_if_body(self,ref={}):
    ok = 1
    ok = ok and self.flags.get('head_done')
    ok = ok and not self.flags.get('eof')
    ok = ok and not self.flags.get('head')

    if not ok:
      return self

    # simply grab into 'body' section
    if ref.get('body'):
      self.sec_info['body_lines'].append(self.line)
      return self

    if not self.flags.get('seccmd'):
      self.sec_info['save']['before_seccmd'].append(self.line)

    else:
      if not self.flags.get('securl'):
        self.sec_info['save']['before_securl'].append(self.line)
      else:
        self.sec_info['body_lines'].append(self.line)

    return self

  def ln_if_top(self,ref={}):
    ok = 1
    ok = ok and not self.flags.get('eof')
    ok = ok and not self.flags.get('head')
    ok = ok and not self.flags.get('head_done')

    if not ok:
      return self

    self.sec_info['top_lines'].append(self.line)
    return self

  def ln_if_head(self,ref={}):
    ok = 1
    ok = ok and not self.flags.get('eof')
    ok = ok and self.flags.get('head')
    if not ok:
      return self

    self.sec_info['head_lines'].append(self.line)

    m = rgx.match('tex.projs.head.@key',self.line)
    if not m:
      return self

    m_value = m.group('value')
    m_key   = m.group('key')

    self.sec_info['head_keyval'].update({ m_key : m_value })

    return self

