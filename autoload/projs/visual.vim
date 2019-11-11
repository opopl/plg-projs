
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

for k in range(start,end+1,1):
  i = k-1
  n = k-start+1
  b[i] = ind + str(n) + " " + b[i]

eof
	
endfunction
