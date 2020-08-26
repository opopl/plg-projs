
if exists("b:projs_did_ftplugin_idat") | finish | endif
let b:projs_did_ftplugin_idat=1

call base#buf#start()

"""projs_ftplugin_idat

let root    = projs#root()

"""projs_ftplugin_tex

" if we are dealing with a 'projs' (La)TeX file
"if ( ( b:dirname == b:root ) && ( b:ext == 'tex' ) )
"
let b:relpath_projs = base#file#reldir( b:dirname, root )

if ( b:dirname == root ) || (len(b:relpath_projs))
	let b:root = root

  call projs#buf#onload_idat()
  
endif
