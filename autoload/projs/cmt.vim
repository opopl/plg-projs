

if 0
  let lines = projs#cmt#author({ 
    \ 'author_id' : author_id 
    \ })
endif

function! projs#cmt#author (...)
  let ref = get(a:000,0,{})

  let lines = []

  call add(lines,'\ifcmt')
  call add(lines,'  author_begin')
  for [k,v] in items(ref)
    call add(lines,printf('   %s %s', k, v))
  endfor
  call add(lines,'  author_end')
  call add(lines,'\fi')

  return lines
  
endfunction
