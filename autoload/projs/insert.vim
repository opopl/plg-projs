
function! projs#insert#template_tex ()
	call projs#insert#template ('tex')
endfunction

function! projs#insert#template_vim ()
	call projs#insert#template ('vim')
endfunction

function! projs#insert#projname ()
	let proj = projs#proj#name()
	call append(line('.'),proj)

endfunction

function! projs#insert#template (type)
	let type  = a:type
	let t     = projs#varget('templates_'.type,{})
	let tlist = sort(keys(t))

	if !len(tlist)
		call projs#echo('No '.type.' templates found, aborting.')
		return
	endif

	let tname = input(type.' template name:','','custom,projs#complete#templates_'.type)
	let tlines = get(t,tname,[])

	call append(line('.'),tlines)
	
endfunction
