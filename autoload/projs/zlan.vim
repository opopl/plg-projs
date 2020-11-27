
function! projs#zlan#data ()
  let zfile = projs#sec#file('_zlan_')

  let zdata = {}
  if !filereadable(zfile)
    return {}
  endif
  let zorder = []

  let lines = readfile(zfile)

  let flags = {}
  let d     = {}

  let zkeys = base#varget('projs_zlan_keys',[])

  while len(lines) 
    let line = remove(lines,0)
    let save = 0

    if ((line =~ '^page') || !len(lines))
      let save = 1
    endif

    if line =~ '^\t'
      for k in zkeys
        let pat  = printf('^\t%s\s\+\zs.*\ze$', k)
        let list = matchlist(line, pat)
        let v    = get(list,0,'')

        if len(v)
          call extend(d,{ k : v })
        endif
      endfor
    endif

    if save
      let url = get(copy(d),'url','')
      if len(url)
        unlet d.url
        call add(zorder,url)
  
        let dd = copy(d)
  
        let struct = base#url#struct(url)
        let host   = get(struct,'host','')
  
        call extend(dd,{ 'host' : host })
  
        call extend(zdata,{ url : dd })
      endif
      let d = {}
    endif

  endw

  call extend(zdata,{ 'order' : zorder })

  return zdata
  
endfunction

function! projs#zlan#save (...)
  let ref   = get(a:000,0,{})

  let zdata = get(ref,'zdata',{})

  let zfile = projs#sec#file('_zlan_')

  let zorder = get(zdata,'order',[])

  let zlines = []
  let zkeys = base#varget('projs_zlan_keys',[])

  for url in zorder
    let d = get(zdata,url,{})
    if len(d)
      call add(zlines,'page')
      for k in zkeys
        let v = ''
        if k == 'url'
          let v = url
        else
          let v = get(d,k,'')
        endif

        if len(v)
          call add(zlines,"\t" . k . ' ' . v)
        endif
      endfor
    endif
  endfor

  call writefile(zlines,zfile)

endfunction
