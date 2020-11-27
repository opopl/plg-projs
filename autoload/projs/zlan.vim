
function! projs#zlan#data ()
  let zfile = projs#sec#file('_zlan_')

  let zdata = {}

  if !filereadable(zfile)
    return zdata
  endif

  let lines = readfile(zfile)

  let flags = {}
  let d     = {}

  let zkeys = base#varget('projs_zlan_keys',[])

  for line in lines
    if line =~ '^page'
      let url = get(copy(d),'url','')
      if len(url)
        unlet d.url
        let dd = copy(d)

        let struct = base#url#struct(url)
        let host   = get(struct,'host','')

        call extend(dd,{ 'host' : host })

        call extend(zdata,{ url : dd })
      endif
      let d = {}

    elseif line =~ '^\t'
      for k in zkeys
        let pat = printf('^\t%s\s\+\zs.*\ze$', k)
        let list = matchlist(line, pat)
        let v = get(list,0,'')
        if len(v)
          call extend(d,{ k : v })
        endif
      endfor
    endif
  endfor

  return zdata
  
endfunction

function! projs#zlan#save (...)
  let ref = get(a:000,0,{})

  let zdata = get(ref,'zdata',{})

endfunction
