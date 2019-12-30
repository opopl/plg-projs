
function! projs#html_out#file (...)
  let ref = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let hroot = projs#html_out#root()
  
  let hfile = join([ hroot, proj, 'main.html' ], '/')
  let hfile = base#file#win2unix(hfile)

  return hfile
  
endfunction

function! projs#html_out#view (...)
  let hfile = projs#html_out#file()
  let hfile = base#file#unix2win(hfile)

  let proj = projs#proj#name()

  if !filereadable(hfile)
    call base#rdwe(printf('No HTML file for: %s',proj))
    return 
  endif

	call base#html#view_in_browser({ 'file' : hfile })

endfunction

function! projs#html_out#root (...)
  let hroot = base#envvar('htmlout','')
  return hroot
endfunction
