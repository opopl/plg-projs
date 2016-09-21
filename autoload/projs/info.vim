
function! projs#info#usedpacks ()

	call projs#update#usedpacks()

	let up = projs#varget('usedpacks',[])
	let po = projs#varget('packopts',{})

	let dc = projs#varget('dc','')
	let dco = projs#varget('dco','')

	call base#echo({   'text' : 'Document Class: ', 'prefix' : ''})
	call base#echo({   'text' : '                '.dc, 'prefix' : ''})

	if strlen(dco)
		call base#echo({   'text' : 'Document Class Options: ', 'prefix' : ''})
		call base#echo({   'text' : '                '.dco, 'prefix' : ''})
	endif

	for p in up
		let o=get(po,p,'')

		call base#echo({   'text' : 'Package: ', 'prefix' : ''})
		call base#echo({   'text' : '         '.p, 'prefix' : ''})
		if strlen(o)
			call base#echo({ 'text' : '         '.o, 'prefix' : ''})
		endif
	endfor
	
endfunction
