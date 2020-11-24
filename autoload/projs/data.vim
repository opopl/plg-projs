
function! projs#data#dict (...)
	let ref = get(a:000,0,{})

	let id   = get(ref,'id','')
	let proj = get(ref,'proj','')

	let a = [ projs#root(), 'data', 'dict' ]
	if len(proj)
		call extend(a,[ proj ])
	endif

	call extend(a,[ printf('%s.i.dat',id) ])

  let file = join(a, '/')
	let dict = base#readdict({ 'file' : file })

	return file
	
endfunction
