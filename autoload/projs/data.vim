
function! projs#data#dict (...)
  let ref = get(a:000,0,{})

  let file = projs#data#dict#file(ref)

  if !filereadable(file) | return {} | endif
    
  let dict = base#readdict({ 'file' : file })

  return dict
  
endfunction


function! projs#data#dict_choose ()
  let dict_dir = projs#data#dict#dir()
  let ids = base#find({ 
    \ "dirs"    : [dict_dir],
    \ "exts"    : base#qw('i.dat'),
    \ "relpath" : 1,
    \ "subdirs" : 1,
    \ "rmext"   : 1,
    \ "fnamemodify" : '',
    \ })
  call base#varset('this',ids)
  let id = input('dict id: ','','custom,base#complete#this')
  return id

endfunction



