
function! projs#url#fb#data (...)
	let ref = get(a:000,0,{})

	let url    = get(ref,'url','')
	let struct = base#url#struct(url)

	let fb_authors = projs#data#dict({ 'id' : 'fb_authors' })

	let p = split(path,'/')
	let auth = get(path,0,'')

	let author_id = get(fb_authors,auth,'')

	let data = {
			\	'author_id' : author_id,
			\	}
	return data
	
endfunction
