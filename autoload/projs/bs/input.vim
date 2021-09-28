

if 0
  call projs#bs#input#url()

  call projs#bs#input#url({ 'zfile' : zfile })
  call projs#bs#input#url({ 'zfile' : zfile, 'prefix' : prefix })
endif

function! projs#bs#input#url (...)
  let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let proj     = projs#proj#name()

  let zfile = projs#sec#file('_zlan_')
  let zfile = get(ref,'zfile',zfile)

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)
  let prefix = get(ref,'prefix',prefix)

  let keep = 1
  let msg = printf('%s %s: ',prefix,'url')

  let msg_head = ''
  let url = ''

  while keep
    let cnt = 0

    let cmpl = ''
    call base#varset('this',[])

    let url = input(msg_head . msg,'','custom,base#complete#this')

    let cnt = 1

    " Base.Util url_parse()
    let u = base#url#parse(url,{ 
        \ 'rm_query' : 1 
        \ })
    let url = get(u,'url','')

    if !len(url)
       let msg_head = "\nNon-zero URL required\n"

    elseif projs#zlan#has({
        \ 'url'   : url,
        \ 'zfile' : zfile
        \ })

       let msg_head = printf("\nURL in ZLAN: %s\n",fnamemodify(zfile,':t'))

    else
       let cnt = 0
    endif

    if cnt 
      continue
    endif

    break
  endw

  return url
endf

if 0
  let author_id = projs#bs#input#author_id ()
endif

function! projs#bs#input#author_id (...)
  let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let proj     = projs#proj#name()

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)
  let prefix = get(ref,'prefix',prefix)

  let msg = printf('%s %s: ',prefix,'author_id')

  let ids = projs#bs#author#ids()

  call base#varset('this',ids)
  let author_id = input(msg,'','custom,base#complete#this')

  return author_id

endfunction

function! projs#bs#input#tags (...)
  let ref = get(a:000,0,{})

  let rootid   = projs#rootid()
  let proj     = projs#proj#name()

  let prefix = printf('[ rootid: %s, proj: %s ]',rootid, proj)

  let msg = printf('%s %s: ',prefix,'tags')

	let tag_list = []
 	call extend(tag_list,	projs#bs#tags#list())

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

endf
