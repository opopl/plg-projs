
function! projs#vim_server#async_build ()
  call projs#action#async_build()
  return ''
endfunction

function! projs#vim_server#async_build_htlatex ()
  call projs#action#async_build_htlatex()
  return ''
endfunction
