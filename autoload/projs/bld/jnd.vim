
function! projs#bld#jnd#pdf (...)
  let ref = get(a:000,0,{})

  let target = base#varget('projs_bld_target','')
  let target = get(ref,'target',target)

  let proj  = projs#proj#name()

  let rel = printf('builds %s src pdf %s jnd.pdf', proj, target)
  let jnd_pdf = base#qw#catpath( projs#rootid(),rel)
  return jnd_pdf
endfunction

function! projs#bld#jnd#tex (...)
  let ref = get(a:000,0,{})

  let proj  = projs#proj#name()
  let proj  = base#x#get(ref,'proj',proj)

  let target = base#varget('projs_bld_target','')
  let target = get(ref,'target',target)

  let target_ext = get(ref,'target_ext','pdf')
  let suffix = ( target_ext == 'pdf' ) ? '' : '_ht'

  let rel = printf('builds %s src %s %s jnd%s.tex', proj, target_ext, target, suffix)
  let jnd_tex = base#qw#catpath( projs#rootid(),rel)
  return jnd_tex
endfunction

