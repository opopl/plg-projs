
function! projs#au#file_onload_csv ()
	call base#buf#start()
	
	StatusLine projs
	TgSet projs_this
	TgAdd plg_projs
	
endfunction

function! projs#au#file_onload_bat ()
	call base#buf#start()

	let root = projs#root()

	let reldir = base#file#reldir(b:dirname,root)
	echo reldir
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
