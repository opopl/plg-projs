
function! projs#zlan#zo#view ()
  let zfile = projs#sec#file('_zlan_')

  call base#fileopen({ 
    \ 'files'    : [zfile] ,
    \ 'load_buf' : 1,
    \ })
  
endfunction

function! projs#zlan#zo#fetch ()
  
endfunction

function! projs#zlan#zo#add ()
  let rootid = projs#rootid()
  let proj   = projs#proj#name()

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)

  let keys = base#varget('projs_zlan_keys',[])

  let d = {}
  for k in keys
    let d[k] = input(printf('%s %s: ',prefix,k),'')
  endfor

  let zfile = projs#sec#file('_zlan_')

  let lines = []
  call add(lines,'page')
  for k in keys
    let v = get(d,k,'')
    if len(v)
      call add(lines,"\t". k . ' ' . v)
    endif
  endfor
  
endfunction
