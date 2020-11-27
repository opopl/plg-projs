
function! projs#zlan#zo#view ()
	let zfile = projs#sec#file('_zlan_')

	call base#fileopen({ 
		\	'files'    : [zfile] ,
		\	'load_buf' : 1,
		\	})
	
endfunction

function! projs#zlan#zo#fetch ()
	
endfunction

function! projs#zlan#zo#add ()
	
endfunction
