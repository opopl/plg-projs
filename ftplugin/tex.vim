
if exists("b:did_projs_ftplugin_tex")
  finish
endif
let b:did_projs_ftplugin_tex = 1

let root    = projs#root()

call base#buf#start()
call projs#buf#check()

"""projs_ftplugin_tex
"""ftp_tex_projs

" if we are dealing with a 'projs' (La)TeX file
"if ( ( b:dirname == b:root ) && ( b:ext == 'tex' ) )
"

if !exists('b:root')
	finish
endif

if ( b:dirname == b:root ) || (len(b:relpath_projs))

  if b:ext == 'tex'
    call projs#buf#onload_tex_tex()

  elseif b:ext == 'sty'
    call projs#buf#onload_tex_sty()
  endif
  
endif



