
function! projs#update#datvars (...)
   call base#plg#loadvars('projs')
endfunction

function! projs#update#varlist ()

		let bvars   = copy(base#varlist())
		let varlist = filter(bvars,"v:val =~ '^projs_'")
		let varlist = base#mapsub(varlist,'^projs_','','g')

    call projs#varset('varlist',varlist)
	
endfunction
