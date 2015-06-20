
fun! projs#complete(...)

  let comps=[]

  if exists("g:projs")
  	let comps=g:projs
  endif
  return join(comps,"\n")
endf
