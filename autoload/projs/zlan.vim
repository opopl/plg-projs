
function! projs#zlan#data ()
  let zfile = projs#sec#file('_zlan_')

  let zdata = {}
  let zorder = []
python3 << eof
import vim
from Base.Zlan import Zlan

zfile = vim.eval('zfile')

z = Zlan({})

z.get_data({ 'file' : zfile })

zdata = z.data
zorder = z.order

eof
  let zdata = py3eval('zdata')
  return zdata

endfunction
