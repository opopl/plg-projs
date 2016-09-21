
function! projs#info#usedpacks ()

	call projs#update#usedpacks()

	let up = projs#varget('usedpacks',[])
	let po = projs#varget('packopts',{})

	for p in up
		let o=get(po,p,'')

		call base#echo({   'text' : 'Package: ', 'prefix' : ''})
		call base#echo({   'text' : '         '.p, 'prefix' : ''})
		if strlen(o)
			call base#echo({ 'text' : '         '.o, 'prefix' : ''})
		endif
	endfor
	
endfunction
