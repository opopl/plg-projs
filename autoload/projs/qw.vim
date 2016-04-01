

function! projs#qw#rf (s)
	if strlen(a:s)
		let ln  = base#qw#rf('plg','projs ' . a:s)
	endif
	return ln
	
endfunction
