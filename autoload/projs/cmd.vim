
function! projs#cmd#varset (vname,...)
	let vname=a:vname
	let val = get(a:000,0)

	if !val
		unlet val
		let val = input('Enter new value:','')
	endif

	call projs#varset(vname,val)
	
endfunction
