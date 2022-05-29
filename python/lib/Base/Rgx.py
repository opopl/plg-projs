
import re

import Base.Util as util

pats = {
  'tex' : {
    'projs' : {
      'seccmd'    : r'^\s*\\(part|chapter|section|subsection|subsubsection|paragraph)\{(.*)\}\s*$',
      ###
      'beginhead' : r'%%beginhead\s*$',
      'endhead'   : r'%%endhead\s*$',
      ###
      'author_id' : r'%%author_id\s+(.*)$',
      'title'     : r'%%title\s+(.*)$',
      'head' : {
         '@key' : r'%%(?P<key>\w+)\s+(?P<value>.*)$',
      },
      'body' : {
         'purl'      : r'^\s*\\Purl\{(.*)\}\s*$',
         'label_sec' : r'^\s*\\label\{sec:(.*)\}\s*$',
         'ii'        : r'^\s*\\ii\{(?P<ii_child>[^{}]+)\}\s*$',
      },
      ###
      'ifcmt'     : r'^\\ifcmt\s*$',
      'fi'        : r'^\\fi\s*$',
      'cmt' : {
        'author_begin' : r'^\s*author_begin\s*$'    ,
        'author_end'   : r'^\s*author_end\s*$'      ,
        'author_id'    : r'^(\s*)author_id\s+(.*)$' ,
        'tags'         : r'^(\s*)tags\s+(.*)$' ,
      }
    }
  },
  # db_import_fs
  'files' : {
    'projs' : {
      # PROJ.*.EXT
      'sfile'        : r'^(?P<proj>\w+)\.(?P<sec>.*)\.(?P<ext>\w+)$',

      # PROJ.EXT
      # _main_, _yml_, _vim_, _perl_ ...
      'sfile_proj'   : r'^(?P<proj>\w+)\.(?P<ext>\w+)$',
    }
  },
  'idat' : {
     'dict' : r'^(\S+)\s+(.*)$'
  },
  'author' : {
    'dict' : r'^(?P<author_id>\S+)\s+(?P<author_bare>.*)$',
    'bare' : {
      # author.bare.inverted
      'inverted' : r'^(?P<last_name>[^,()]+),(?P<first_name>[^,()]+)(?:\s*|\s+\((?P<info>.*)\))$'
      #'inverted' : r'^(?P<last_name>[^,]+),(?P<first_name>[^,]+)\s*$'
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
def rgx_match(pattern, string, flags='', index=0):
  m = re.search(rf'{pattern}',string)
  if not m:
    return None 

  mtch = m.group(0)
  result = (index and m.group(index)) or m.group(0)

  return result

def rgx_sub(pattern, replacement, string):
  result = re.sub(rf'{pattern}',rf'{replacement}',string)
  return result

def match(pat_id,line):
  pat = util.get( pats, pat_id )
  if not pat:
    return

  m = re.match(pat,line)
  return m

