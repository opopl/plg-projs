
function! projs#zlan#data ()
  let f_zlan = projs#sec#file('_zlan_')

  let zdata = {}
  let zorder = []
python3 << eof
import vim
from Base.Zlan import Zlan

f_zlan = vim.eval('f_zlan')

z = Zlan({})

z.get_data({ 'file' : f_zlan })

zdata = z.data
zorder = z.order

eof
	let zdata = py3eval('zdata')
	return zdata

endfunction
