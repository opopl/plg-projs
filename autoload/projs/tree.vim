
function! projs#tree#file (...)
  let ref = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let file = join([ projs#root(), printf('%s.tree',proj) ],'/')
  return file
  
endfunction
