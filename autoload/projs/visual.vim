
" ===========================================
"METHODS:
"  projs#visual#ii_to_new_secs (start, end)
"
" ===========================================
"
function! projs#visual#append_to_sec (start, end, ... )
  let start = a:start
  let end   = a:end

  let sec = get(a:000,0,'')
  if !strlen(sec)
    let msg_a = [
      \  "Section: ",  
      \  ]
    let msg = join(msg_a,"\n")
    let r = { 'complete' : 'custom,projs#complete#secnamesall' }
    let sec = base#input_we(msg, '' , r)
  endif

  let lines = base#vim#visual_selection()
  let r = {
      \  'sec'   : sec,
      \  'lines' : lines,
      \  }
  call projs#sec#append(r)

  let r_cut = { 
    \ 'start' : start,
    \ 'end'   : end }
  call base#buf#cut(r_cut)

endf

function! projs#visual#ii_to_new_secs (start, end, ... )

  let start = a:start
  let end   = a:end

  let lines = base#vim#visual_selection()

python3 << eof
import vim,re
from itertools import repeat

lines = vim.eval('lines')
start = int(vim.eval('start'))
end   = int(vim.eval('end'))

b = vim.current.buffer

secs = []

for k in range(start, end + 1, 1):
  i = k - 1
  n = k - start + 1
  m = re.search(r'^\\ii{(\w+)}', b[i])
  if m:
    sec = m.group(1)
    secs.append(sec)

eof
  let secs = py3eval('secs')
  for sec in secs
    let r = {
        \  'git_add' : 1,
        \  'rewrite' : 0,
        \  }
    call projs#sec#new(sec, r)
  endfor

  let cmds_done = ['echo 222']
  for sec in secs
    call add(cmds_done, printf('call base#tg#go("%s")',sec) )
  endfor
  let opts = { 'cmds_done' : cmds_done }
  call base#tg#update('projs_this',opts)
  
endfunction
