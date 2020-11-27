
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
        "Same as |match()|, but return a |List|.  The first item in the
        "list is the matched string, same as what matchstr() would
        "return.  Following items are submatches, like "\1", "\2", etc.
        "in |:substitute|.  When an optional submatch didn't match an
        "empty string is used.  Example: 
        "echo matchlist('acd', '\(a\)\?\(b\)\?\(c\)\?\(.*\)')
        "Results in: ['acd', 'a', '', 'c', 'd', '', '', '', '', '']
        "When there is no match an empty list is returned.
        "
        "Can also be used as a |method|: >
        "GetList()->matchlist('word')
      
    endif
  endfor

  return zdata
  
endfunction
