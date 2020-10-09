
function! projs#fc#match_proj (...)
  let ref = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let hl   = 'WildMenu'
  let hl   = get(ref,'hl',hl)

  let s:obj = { 
    \ 'proj' : proj,
    \ 'hl'   : hl,
    \ }

  function! s:obj.init (...) dict
      let proj = self.proj
      let hl   = self.hl

      call matchadd(hl,'\s\+'.proj.'\s\+')
      call matchadd(hl,proj)
  endfunction
    
  let Fc = s:obj.init
  return Fc
  
endfunction
