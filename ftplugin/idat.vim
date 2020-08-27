
if exists("b:projs_did_ftplugin_idat") | finish | endif
let b:projs_did_ftplugin_idat=1

"""projs_ftplugin_idat

call base#buf#start()
call projs#buf#check()

if exists("b:root")
	if ( b:dirname == b:root ) || (len(b:relpath_projs))
	  call projs#buf#onload_idat()
	endif
endif
