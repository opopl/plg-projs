"{
function! projs#input#tags (...)
	let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let proj     = projs#proj#name()

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)
	let prefix = base#x#get(ref,'prefix',prefix)

  let msg = printf('%s %s: ',prefix,'tags')

	let tag_list = []
	call extend(tag_list,projs#bs#tags#list() )
	call extend(tag_list,projs#db#tag_list() )

	let tag_list = base#uniq(tag_list)
	call sort(tag_list)

	let r = { 
		\ 'list'   : tag_list,
		\ 'thing'  : 'tag',
		\ 'prefix' : 'select',
		\ 'msg'    : msg,
		\ 'header' : [
				\ 'projs/bs tags selection dialog',
				\ ],
		\ }
	let tags = base#inpx#ctl(r)
  
  return tags
	
endfunction
"} end: 
