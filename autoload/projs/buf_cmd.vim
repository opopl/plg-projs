
function! projs#buf_cmd#sec_new (...)
	if !exists("b:sec")
		call base#rdwe('b:sec is not defined')
		return 
	endif

	call projs#sec#new(b:sec)
	edit!

	call base#rdwe('OK: sec_new')
	
endfunction
