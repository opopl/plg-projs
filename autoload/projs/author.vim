
if 0
  call tree
    called by
      projs#insert#ii_url
endif

function! projs#author#get (...)
  let ref = get(a:000,0,{})

  let author_id = get(ref,'author_id','')

  let data   = projs#data#dict({ 'id' : 'authors' })
  let author = get(data,author_id,'')

  return author
  
endfunction

"if 0
"  usage
"    let file = projs#author#file({ 'proj' : proj})
"    let file = projs#author#file()
"  call tree
"    called by
"    calls
"      projs#data#dict#file
"endif

function! projs#author#file (...)
  let ref = get(a:000,0,{})

  let proj = get(ref,'proj','')

  let file = projs#data#dict#file({ 'proj' : proj, 'id' : 'authors' })
  let dir  = fnamemodify(file,':p:h')
  call base#mkdir(dir)

  return file

endfunction

function! projs#author#tex_cmt (...)
  let lines = []

  call add(lines,'\ifcmt')
  call add(lines,'\fi')

endfunction

if 0
endif

function! projs#author#add (...)
  let ref = get(a:000,0,{})

  let author_id = get(ref,'author_id','')
  let author    = get(ref,'author','')

  let hash   = projs#data#dict({ 'id' : 'authors' })
  call extend(hash,{ author_id : author })
  call base#varset('projs_hash_authors',hash)

  call projs#author#hash_save ()

endfunction

function! projs#author#hash_save ()
  let file = projs#author#file()

  let hash = base#varget('projs_hash_authors',{})

  let ids = sort(keys(hash))
  let ids = base#uniq(ids)

  let lines = [] 
  
  for author_id in ids
    let author = get(hash,author_id,'')

    call add(lines, printf('%s %s', author_id, author ))
  endfor

  call writefile(lines,file)
  call base#rdw( printf('Authors file updated, rootid: %s', projs#rootid() )  )
endfunction

if 0
  call tree
    called by
      projs#insert#ii_url
endif

function! projs#author#add_prompt (...)
  let ref       = get(a:000,0,{})

  let author_id = get(ref,'author_id','')

  let author = ''
  let author = input(printf('[rootid: %s, author_id: %s, Add Author] Surname, Firstname: ', projs#rootid(), author_id ),author)
  if len(author)
    call projs#author#add({ 'author' : author, 'author_id' : author_id })
    echo printf('[rootid: %s] Added author: %s => %s',projs#rootid(), author_id, author)
  endif

  return author

endfunction

function! projs#author#select_id (...)
  let ref = get(a:000,0,{})

  let author_id = get(ref,'author_id','')

  let ids   = has_key(ref,'ids') ? get(ref,'ids') : projs#author#ids_db()

  let r = {
    \ 'list'    : ids,
    \ 'thing'   : 'author_id',
    \ 'prefix'  : 'select',
    \ 'default' : author_id,
    \ 'header'  : [
      \ 'author_id selection dialog',
      \ ],
    \ }
  let author_id = base#inpx#ctl(r)

  return author_id

endfunction

"if 0
"  purpose
"    choose author data via command-line input
"  usage
"   let a_data = projs#author#select()
"   let a_data = projs#author#select({ 'author_id' : author_id })
"  call tree
"    called by
"      projs#insert#cmt_author
"endif

function! projs#author#select (...)
  let ref = get(a:000,0,{})

  let author_id = get(ref,'author_id','')

  let ids = projs#author#ids()

  let rootid = projs#rootid()

  call base#varset('this',ids)

  while(1)
    let author_id = input( printf('[rootid: %s] author_id: ',rootid),author_id,'custom,base#complete#this')
    if len(author_id)
      break
    endif
  endw

  let author = projs#author#get({ 'author_id' : author_id })
  let author = input(printf('[rootid: %s] author: ',rootid),author)

  let a_data = {
      \ 'author'    : author,
      \ 'author_id' : author_id,
      \ }
  return a_data

endfunction

function! projs#author#hash ()
  let hash   = projs#data#dict({ 'id' : 'authors' })
  return hash
endfunction

function! projs#author#ids_db ()
  let dbfile = base#qw#catpath('html_root','h.db')
  
  let q = 'SELECT DISTINCT id FROM authors ORDER BY id ASC'
  let p = []
  
  let ids = pymy#sqlite#query_as_list({
    \ 'dbfile' : dbfile,
    \ 'p'      : p,
    \ 'q'      : q,
    \ })
  return ids

endfunction

function! projs#author#ids ()
  let hash = projs#author#hash()
  let ids = keys(hash)
  let ids = base#uniq(ids)

  return ids
endfunction
