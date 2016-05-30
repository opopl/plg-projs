
function! projs#list#exclude ()
	let f = base#qw#catpath('plg','projs data list_exclude.i.dat')
	let exclude =  base#readarr(f)

	return exclude
endfunction
