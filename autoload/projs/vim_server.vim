
function! projs#vim_server#async_build_bare ()
  call projs#action#async_build_bare()
  return ''
endfunction

function! projs#vim_server#async_build_htlatex ()
  call projs#action#async_build_htlatex()
  return ''
endfunction

function! projs#vim_server#view_project (...)
  let proj = get(a:000,0,'')
  call projs#viewproj(proj)
  return ''
endfunction

function! projs#vim_server#sec_open (...)
  let sec = get(a:000,0,'')
  call projs#sec#open_load_buf(sec)
  return ''
endfunction

function! projs#vim_server#html_out_view (...)
  call projs#action#html_out_view()
  return ''
endfunction

function! projs#vim_server#pdf_out_view (...)
  PrjPdfView
  return ''
endfunction

function! projs#vim_server#build_cleanup (...)
  PrjBuild Cleanup
  return ''
endfunction
