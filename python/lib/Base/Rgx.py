
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
     'dict' : r'^(\S+)\s+(.*)$'
  },
  'author' : {
    'bare' : {
      'inverted' : r'^([^,]+),([^,]+)$'
    }
  },
  'url' : {
    'facebook' : { 
       'base' : r'facebook\.com$',
       'post_user' : r'^\/([\S^\/]+)\/posts\/(\d+)$',
       'permalink' : r'^\/permalink.php$',
    }
  }
}

def search(pat_id,line):
  pat = util.get( pats, pat_id )
  if not pat:
    return

  patc = re.compile(pat)
  m = patc.search(line)

  return m

# clone of Plg::Projs::Regex rgx_match
def rgx_match(pattern,string,flags='',index=0):
  m = re.search(pattern,string)
  if not m:
    return None 

  mtch = m.group(0)
  result = (index and m.group(index)) or m.group(0)

  return result

def match(pat_id,line):
  pat = util.get( pats, pat_id )
  if not pat:
    return

  m = re.match(pat,line)
  return m
