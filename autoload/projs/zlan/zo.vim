
function! projs#zlan#zo#view ()
  let zfile = projs#sec#file('_zlan_')

  call base#fileopen({ 
    \ 'files'    : [ zfile ],
    \ 'load_buf' : 1,
    \ })
  
endfunction

function! projs#zlan#zo#fetch ()
  
endfunction

function! projs#zlan#zo#add ()
  let rootid = projs#rootid()
  let proj   = projs#proj#name()

  let zdata = projs#zlan#data()
  let l = keys(zdata)

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)

  let keys = base#varget('projs_zlan_keys',[])

  let d = {}
  for k in keys
    let msg = printf('%s %s: ',prefix,k)

    let keep = 1
    while keep
      let d[k] = input(msg,'')

	    if k == 'url'
	      " code
	    endif

      break
    endw
  endfor

  let url = get(copy(d),'url','')
  unlet d.url

  
endfunction
