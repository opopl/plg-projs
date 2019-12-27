
function! projs#html_out#file (...)
	let ref = get(a:000,0,{})

	let proj = projs#proj#name()
	let proj = get(ref,'proj','')

	let hroot = projs#html_out#root()
	
	let hfile = join([ hroot, proj, 'main.html' ], '/')
	
endfunction

function! projs#html_out#root (...)
	let hroot = base#envvar('htmlout','')
	return hroot
endfunction
