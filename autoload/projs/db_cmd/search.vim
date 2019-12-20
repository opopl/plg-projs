
if 0
  called in
    projs#db_cmd#search
endif

function! projs#db_cmd#search#visual_open ()
  let lines = base#vim#visual_selection()

python3 << eof
import vim,re
lines = vim.eval('lines')
p = re.compile(r'^\s*\d+\s+(\w+)\s+(\w+)\s+(.*)\s*$')
data = []
for line in lines:
  m = p.match(line)
  if m:
    proj = m.group(1)
    sec  = m.group(2)
    data.append({ 'proj' : proj, 'sec' : sec })

eof
  let data = py3eval('data')
  echo data
  
endfunction
