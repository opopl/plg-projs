
function! projs#au#file_onload_csv ()
  call base#buf#start()
  
  StatusLine projs
  TgSet projs_this
  TgAdd plg_projs
  
endfunction

function! projs#au#file_onload_bat ()
  call base#buf#start()

  let root = projs#root()

  let common = base#file#commonroot([ b:dirname,root ])
  if !len(common)
    return 
  endif

  let proj = matchstr(b:basename, '^b_\zs\w\+\ze_\(pdflatex\|htlatex\)\.bat$')
  if len(proj)
    let b:proj = proj
  endif
endfunction

function! projs#au#file_onload_vim ()
  call base#buf#start()
  
  StatusLine projs
  TgSet projs_this
  TgAdd plg_projs
  TgAdd plg_base
  
endfunction

function! projs#au#file_onload_make ()
  call base#buf#start()
  
  StatusLine projs
  TgSet projs_this
  TgAdd plg_projs
  TgAdd plg_base
  
endfunction
