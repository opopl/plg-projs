
function! projs#img#convert (...)
	let ref = get(a:000,0,{})

	let img_root = base#path('img_root')
	let img_db   = base#file#catfile([ img_root, 'img.db' ])

	let img_num = input('Image number: ','')
	
endfunction
