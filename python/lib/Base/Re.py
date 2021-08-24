
import re

import Base.Util as util

pats = {
  'tex' : {
    'projs' : {
      'seccmd'    : r'^\s*\\(part|chapter|section|subsection|subsubsection|paragraph)\{(.*)\}\s*$',
      'beginhead' : r'%%beginhead\s*$',
      'endhead'   : r'%%endhead\s*$',
      'author_id' : r'%%author_id\s+(.*)$',
      'ifcmt'     : r'^\\ifcmt\s*$',
      'fi'        : r'^\\fi\s*$',
      'cmt' : {
        'author_begin' : r'^\s*author_begin\s*$'    ,
        'author_end'   : r'^\s*author_end\s*$'      ,
        'author_id'    : r'^(\s*)author_id\s+(.*)$' ,
      }
    }
  },
  'idat' : {
     'dict' : r'^(\w+)\s+(.*)$'
  },
  'author' : {
    'bare' : {
      'inverted' : r'^([^,]+),([^,]+)$'
    }
  }
}

def match(pat_id,line):
  pat = util.get( pats, pat_id )
  if not pat:
    return

  m = re.match(pat,line)
  return m

