
function! projs#cmd#varset (...)
	let vname = get(a:000,0,'')
	let val   = get(a:000,1,'')

	if !strlen(vname)
		unlet vname
		let vname = input('PROJS variable name:','','custom,projs#complete#varlist')
		if !strlen(vname)
			return
		endif
	endif

	if !strlen(val)
		unlet val
		if vname == 'buildmode'
			let val = input('Enter new value for '.vname. ':','','custom,projs#complete#buildmodes')
		else
			let val = input('Enter new value for '.vname.':','')
		endif
	endif

	call projs#varset(vname,val)

	redraw!
	call projs#echo('Variable set: ' . vname . ' => ' . val)
	
endfunction
