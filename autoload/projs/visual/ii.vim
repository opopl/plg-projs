
"called by 
"  projs#visual#ii_to_new_secs

function! projs#visual#ii#secs (start,end,...)
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
  m = re.search(r'^\s*\\ii{(.*)}\s*$', b[i])
  if m:
    sec = m.group(1)
    secs.append(sec)

eof
  let secs = py3eval('secs')
  return secs
  
endfunction
