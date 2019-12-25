
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

    let lines_tex = []
    call add(lines_tex,printf('%%%%url %s',url) )
    call add(lines_tex,' ' )
    call add(lines_tex,printf('\url{%s}',url) )

    let do_insert = input('Insert url lines? (1/0): ',1)
    if do_insert
python3 << eof
import vim,in_place,re

file      = vim.eval('file')
lines_tex = vim.eval('lines_tex')

is_head = 0

lines = []
with open(file,'r') as f:
  for line in f:
    if re.match(r'^%%beginhead', line):
      is_head = 1
    if re.match(r'^%%endhead', line):
      is_head = 0
      lines.append(tex_lines)
    lines.append(line)

f = open(file,'w+')
f.write(lines)
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
