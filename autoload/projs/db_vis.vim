
if 0
  used in:
    projs#db_cmd#buf_data
endif

function! projs#db_vis#update ()
  let lines = base#vim#visual_selection()

  for line in lines
    let col = matchstr(line,'^\s*\d\+\s\+\zs\(\w\+\)\ze.*$')
    let val = matchstr(line,'^\s*\d\+\s\+\w\+\s*\zs.*\ze$')
  endfor

  let sec  = projs#proj#secname()
  let proj = projs#proj#name()
  let root = projs#root()

  let file = projs#sec#file(sec)

  let new_val = input(printf('[ "%s" column ] new value: ',col), val)

  let dbfile = projs#db#file()
  
  let t = "projs"
  let h = {
    \  col : new_val,
    \  }

  if col == 'url'
    let url = new_val

    let b:url = url

    let do_insert = input('Insert url lines? (1/0): ',1)
    if do_insert
python3 << eof
import vim,in_place,re

file      = vim.eval('file')
url       = vim.eval('url')

is_head = 0

url_cmt_done = 0
url_tex_done = 0

url_cmt = '%%url ' + url 
url_tex = [ 
  r'{ \small'          ,
  r'\vspace{0.5cm}'    ,
  r'\url{' + url + '}' ,
  r'\vspace{0.5cm}'    ,
  r'}'                 ,
]

lines_w = []
f = open(file,'r')
lines = f.read().splitlines()

try:
  for line in lines:
      end_head = 0
      after_head = 0
      if re.match(r'^%%url\s+', line):
        url_cmt_done = 1
      if re.match(r'^\\url\{.*\}\s*$', line):
        url_tex_done = 1
      if re.match(r'^%%beginhead', line):
        is_head = 1
      if re.match(r'^%%endhead', line):
        is_head = 0
        end_head = 1
        if url_cmt_done == 0:
          lines_w.append(url_cmt)
      lines_w.append(line)

  if url_tex_done == 0:
     lines_w.extend(url_tex)
finally:
  f.close()

f = open(file,'w+')
try:
  for line in lines_w:
    f.write(line)
    f.write("\n")
finally:
  f.close()
  
eof
    endif
  endif

  let w = {
      \  'sec'  : sec,
      \  'proj' : proj,
      \  }
  
  let ref = {
    \ "dbfile" : dbfile,
    \ "t"      : t,
    \ "h"      : h,
    \ "w"      : w
    \ }
    
  call pymy#sqlite#update_hash(ref)

  
endfunction
