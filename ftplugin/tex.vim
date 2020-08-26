
if exists("b:did_projs_ftplugin_tex")
  finish
endif
let b:did_projs_ftplugin_tex = 1

let root    = projs#root()
call base#buf#start()

"""projs_ftplugin_tex

" if we are dealing with a 'projs' (La)TeX file
"if ( ( b:dirname == b:root ) && ( b:ext == 'tex' ) )
"
let b:relpath_projs = base#file#reldir( b:dirname, root )

if ( b:dirname == root ) || (len(b:relpath_projs))
	let b:root = root

  if b:ext == 'tex'
    call projs#buf#onload_tex_tex()

  elseif b:ext == 'sty'
    call projs#buf#onload_tex_sty()
  endif
  
endif



