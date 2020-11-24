

if 0
	Usage
		let data = projs#url#fb#data({ 'url' : url })
		echo data
endif

function! projs#url#fb#data (...)
	let ref = get(a:000,0,{})

	let url    = get(ref,'url','')
	let struct = base#url#struct(url)

	let path = get(struct,'path','')

	let fb_authors = projs#data#dict({ 'id' : 'fb_authors' })

	let path_a = split(path,'/')
	let auth   = get(path_a,0,'')

	let author_id = get(fb_authors,auth,'')

	let data = {
			\	'author_id' : author_id,
			\	}
	return data
	
endfunction
