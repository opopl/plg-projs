
"""projs_ftplugin_vim

if exists("b:did_projs_ftplugin_vim")
  finish
endif
let b:did_projs_ftplugin_vim = 1

call base#buf#start()
call projs#buf#check()

" if we are dealing with a 'projs' (La)TeX file
"if ( ( b:dirname == b:root ) && ( b:ext == 'tex' ) )

if exists('b:root') && ( b:dirname == b:root )
	if b:ext == 'vim'
		call projs#buf#onload_vim()
	endif
endif
