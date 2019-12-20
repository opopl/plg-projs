
if 0
  called by:
    projs#db_cmd#sec_add_tags
endif

function! projs#db_cmd#sec_add_tags#update()
  let lines = base#vim#visual_selection()

python3 << eof
import vim,re

lines = vim.eval('lines')
p = re.compile(r'^\s*\d+\s+(\w+)\s*$')
secs = []
for line in lines:
  m = p.match(line)
  if m:
    sec  = m.group(1)
    secs.append(sec)

eof
  let secs = py3eval('secs')
  for sec in secs
  endfor
endf
