
if 0
  called by
    projs#zlan#zo#add
endif

function! projs#zlan#save (...)
  let ref = get(a:000,0,{})

  let zfile = projs#sec#file('_zlan_')
  let zfile = get(ref,'zfile',zfile)

  let zdata    = get(ref,'zdata',{})

  let d_i      = get(ref,'d_i',{})
  let d_i_list = get(ref,'d_i_list',[])
  if len(d_i)
    call add(d_i_list,d_i)
  endif

python3 << eof
import vim
from Base.Zlan import Zlan

zfile    = vim.eval('zfile')
zdata    = vim.eval('zdata')
d_i_list = vim.eval('d_i_list')

len_main = len(zdata['lines_main'])
len_eof  = len(zdata['lines_eof'])

Zlan().save2fs({ 
  'data'     : zdata,
  'file_out' : zfile,
  'd_i_list' : d_i_list,
})
  
eof
endf

function! projs#zlan#data (...)
  let ref = get(a:000,0,{})

  let zfile = projs#sec#file('_zlan_')
  let zfile = get(ref,'zfile',zfile)

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

function! projs#zlan#count (...)
  let ref = get(a:000,0,{})

  let zfile = projs#sec#file('_zlan_')
  let zfile = get(ref,'zfile',zfile)

  let zdata = projs#zlan#data({ 
    \ 'zfile' : zfile 
    \ })

  let zorder = get(zdata,'order',{})
  let cnt = {}
  for k in base#qw('all on')
    let lst = get(zorder,k,[])
    call extend(cnt,{ k : len(lst) })
  endfor

  return cnt

endfunction

function! projs#zlan#has (...)
  let ref = get(a:000,0,{})

  let zfile = projs#sec#file('_zlan_')
  let zfile = get(ref,'zfile',zfile)

  let url = get(ref,'url','')

  let zdata = projs#zlan#data({ 
    \ 'zfile' : zfile 
    \ })

  let zorder     = get(zdata,'order',{})
  let zorder_all = get(zorder,'all',[])

  if base#inlist(url,zorder_all)
    return 1
  endif

  return 
endfunction
