
function! projs#vim_server#async_build ()
  call projs#action#async_build()
  return ''
endfunction

function! projs#vim_server#async_build_htlatex ()
  call projs#action#async_build_htlatex()
  return ''
endfunction

function! projs#vim_server#sec_open (...)
  let sec = get(a:000,0,'')
  call projs#sec#open(sec)
  return ''
endfunction
