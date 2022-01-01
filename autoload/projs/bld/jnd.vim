
function! projs#bld#jnd#pdf (...)
  let ref = get(a:000,0,{})

  let target = base#varget('projs_bld_target','')
  let target = get(ref,'target',target)

  let proj  = projs#proj#name()

  let jnd_pdf = base#qw#catpath( projs#rootid(),printf('builds %s src %s jnd.pdf',proj,target))
  return jnd_pdf
endfunction

function! projs#bld#jnd#tex (...)
  let ref = get(a:000,0,{})

  let proj  = projs#proj#name()
  let proj  = base#x#get(ref,'proj',proj)

  let target = base#varget('projs_bld_target','')
  let target = get(ref,'target',target)

  let jnd_tex = base#qw#catpath( projs#rootid(),printf('builds %s src %s jnd.tex',proj,target))
  return jnd_tex
endfunction
