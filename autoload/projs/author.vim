
if 0
	call tree
		called by
			projs#insert#ii_url
endif

function! projs#author#get (...)
	let ref = get(a:000,0,{})

	let a_id = get(ref,'a_id','')

	let data   = projs#data#dict({ 'id' : 'authors' })
	let author = get(data,a_id,'')

	return author
	
endfunction

function! projs#author#hash ()
	let hash   = projs#data#dict({ 'id' : 'authors' })
	return hash
endfunction

function! projs#author#ids ()
	let hash   = projs#author#hash()
	let ids = keys(hash)
	let ids = base#uniq(ids)
	return ids
endfunction
