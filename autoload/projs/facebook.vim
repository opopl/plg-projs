
function! projs#facebook#add_author_id (...)
	let ref = get(a:000,0,{})

	let author_id = get(ref,'author_id','')
	let fb_auth   = get(ref,'fb_auth','')

  let fb_authors = projs#data#dict({ 'id' : 'fb_authors' })
	call extend(fb_authors,{ fb_auth : author_id })

	let f = projs#facebook#file_auth ()

	let lines = []
	for k in sort(keys(fb_authors))
		let v = get(fb_authors,k,'')
		call add(lines,printf('%s %s',k,v))
	endfor
	call writefile(lines,f)
	
endfunction

function! projs#facebook#file_auth ()
  let f = projs#data#dict_file({ 'id' : 'fb_authors' })
	return f

endfunction
