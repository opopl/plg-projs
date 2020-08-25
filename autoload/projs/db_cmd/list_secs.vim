
if 0
  called in
    projs#db_cmd#list_secs
endif

function! projs#db_cmd#list_secs#visual_open ()
  let lines = base#vim#visual_selection()

python3 << eof
import vim,re

lines = vim.eval('lines')
p = re.compile('^\s*\d+\s+(\w+)\s*$')
data = []
for line in lines:
  m = p.match(line)
  if m:
    sec  = m.group(1)
    d = { 'sec' : sec }
    data.append(d)

eof
  let data = py3eval('data')
  for rwh in data
    let sec  = get(rwh,'sec','')
    call projs#sec#open(sec,{
			\	'load_buf' : 1 
			\	})
  endfor
  
endfunction
