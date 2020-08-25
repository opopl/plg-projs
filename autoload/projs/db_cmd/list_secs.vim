
if 0
  called in
    projs#db_cmd#list_secs
endif

function! projs#db_cmd#list_secs#visual_open ()
  let lines = base#vim#visual_selection()

  echo lines
  return 

python3 << eof
import vim,re

lines = vim.eval('lines')
p = re.compile('^\s*(\w+)\s*$')
data = []
for line in lines:
  m = p.match(line)
  if m:
    sec  = m.group(1)
    print(sec)
    d = { 'sec' : sec }
    data.append(d)

eof
  let data = py3eval('data')
  for rwh in data
    let sec  = get(rwh,'sec','')
    call projs#sec#open_load_buf(sec)
  endfor
  
endfunction
