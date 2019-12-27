
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

  let pat = '^b_\zs\w\+\ze_\(pdflatex\|htlatex\)\.bat$'
  let res = matchlist(b:basename, pat)

  let proj = get(res,0,'')
  let mode = get(res,1,'')

  if len(proj)
    let b:proj = proj
  endif

  if len(mode)
    let b:sec = printf('_build_%s_',mode)
  endif

  StatusLine projs
  TgSet projs_this
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
