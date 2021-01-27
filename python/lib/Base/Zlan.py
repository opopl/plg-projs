
import os,sys

def add_libs(libs):
  for lib in libs:
    if not lib in sys.path:
      sys.path.append(lib)

plg = os.environ.get('PLG')
add_libs([ os.path.join(plg,'projs','python','lib') ])
import Base.DBW as dbw
import Base.Util as util
import Base.Const as const

def data(ref={}):
  zfile = util.get(ref,'file')
  if not file:
    return {}

  zdata = {}
  if not os.path.isfile(zfile):
    return {}

  zorder = []

  with open(zfile,'r') as f:
    lines = f.read()

    flags = {}
    d = {}

#let zkeys = base#varget('projs_zlan_keys',[])
    #zkeys =
    while len(lines):
      line = lines.pop(0)
      save = 0

      m = re.match('^page', line)
      
      #If zero or more characters at the beginning of string match the regular expression pattern, 
      #return a corresponding match object. 
      #Return None if the string does not match the pattern; note that this is different from a zero-length match.
      #https://docs.python.org/3/library/re.html
  

  #while len(lines) 
    #let line = remove(lines,0)
    #let save = 0

    if ((line =~ '^page') || !len(lines))
      let save = 1
    endif

    if line =~ '^\t'
      for k in zkeys
        let pat  = printf('^\t%s\s\+\zs.*\ze$', k)
        let list = matchlist(line, pat)
        let v    = get(list,0,'')

        if len(v)
          call extend(d,{ k : v })
        endif
      endfor
    endif

    if save
      let url = get(copy(d),'url','')
      if len(url)
        unlet d.url
        call add(zorder,url)
  
        let dd = copy(d)
  
        let struct = base#url#struct(url)
        let host   = get(struct,'host','')
  
        call extend(dd,{ 'host' : host })
  
        call extend(zdata,{ url : dd })
      endif
      let d = {}
    endif

  endw

  call extend(zdata,{ 'order' : zorder })

  return zdata
  
endfunction
