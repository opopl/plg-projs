
function! projs#data#dict (...)
  let ref = get(a:000,0,{})

  let file = projs#data#dict_file(ref)

  if !filereadable(file) | return {} | endif
    
  let dict = base#readdict({ 'file' : file })

  return dict
  
endfunction

function! projs#data#dict_file (...)
  let ref = get(a:000,0,{})

  let id   = get(ref,'id','')
  let proj = get(ref,'proj','')

  let a = [ projs#root(), 'data', 'dict' ]
  if len(proj)
    call extend(a,[ proj ])
  endif

  call extend(a,[ printf('%s.i.dat',id) ])

  let file = join(a, '/')
  return file

endfunction
