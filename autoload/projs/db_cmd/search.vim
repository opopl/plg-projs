
function! projs#db_cmd#search#visual_open ()
  let lines = base#vim#visual_selection()

  if 0
    <++>
python3 << eof
import vim,re
lines = vim.eval('lines')
p = re.compile(r'^\s*\d+\s+(\w+)\s+(\w+)\s+(.*)\s*$')
for line in lines:
  m = p.match(line)
  if m:
    proj = m.group(1)
    proj = m.group(2)
  
eof
  endif
  
endfunction
