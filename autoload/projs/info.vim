
function! projs#info#usedpacks ()

	call projs#update#usedpacks()

	let up = projs#varget('usedpacks',[])
	let po = projs#varget('packopts',{})

	for p in up
		call base#echo({ 'text' : 'Package: '.p, 'prefix' : ''})
	endfor
	
endfunction
