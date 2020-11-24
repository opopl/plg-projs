
function! projs#url#fb#data (...)
	let ref = get(a:000,0,{})

	let url    = get(ref,'url','')
	let struct = base#url#struct(url)
	
endfunction
