
function! projs#info#usedpacks ()

	call projs#update#usedpacks()

	let up = projs#varget('usedpacks',[])
	let po = projs#varget('packopts',{})
	
endfunction
