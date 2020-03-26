
if 0
	

	Purpose:
		
	Usage:
		call projs#xml#update_col ()
	Call tree:
		calls:
		
		called by:
			projs#db_vis#update
endif

function! projs#xml#update_col(...)
  let ref = get(a:000,0,{})

  let col = get(ref,'col','')
  let val = get(ref,'val','')

  let sec = get(ref,'sec','')
  let proj = get(ref,'proj','')

  let xmlfile = get(ref,'xmlfile',projs#xmlfile())

python3 << eof
import vim
import xml.etree.ElementTree as ET

xmlfile = vim.eval('xmlfile')
sec = vim.eval('sec')
proj = vim.eval('proj')
val = vim.eval('val')
col = vim.eval('col')

tree = ET.ElementTree(file=xmlfile)
root = tree.getroot()
eof
endf
