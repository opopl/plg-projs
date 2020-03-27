
if exists("b:did_projs_ftplugin_tex")
  finish
endif
let b:did_projs_ftplugin_tex = 1

let b:root    = projs#root()
call base#buf#start()

"""projs_ftplugin_tex

" if we are dealing with a 'projs' (La)TeX file
"if ( ( b:dirname == b:root ) && ( b:ext == 'tex' ) )

if ( b:dirname == b:root )
  if b:ext == 'tex'
    call projs#buf#onload_tex_tex()

  elseif b:ext == 'sty'
    call projs#buf#onload_tex_sty()
  endif
  
endif



