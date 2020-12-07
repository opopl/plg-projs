
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

function! projs#author#file (...)
  let ref = get(a:000,0,{})

  let proj = get(ref,'proj','')

  let file = projs#data#dict_file({ 'proj' : proj, 'id' : 'authors' })
  let dir  = fnamemodify(file,':p:h')
  call base#mkdir(dir)

  return file

endfunction

function! projs#author#tex_cmt (...)
  let lines = []

  call add(lines,'\ifcmt')
  call add(lines,'\fi')

endfunction

function! projs#author#add (...)
  let ref = get(a:000,0,{})

  let a_id = get(ref,'a_id','')
  let a    = get(ref,'a','')

  let hash   = projs#data#dict({ 'id' : 'authors' })
  call extend(hash,{ a_id : a })
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

  let author_id = get(ref,'a_id','')

  let author = input(printf('[rootid: %s, Add Author] Surname, Firstname: ',projs#rootid()),'')
  if len(author)
    call projs#author#add({ 'a' : author, 'a_id' : author_id })
    echo printf('[rootid: %s] Added author: %s => %s',projs#rootid(), author_id, author)
  endif

  return author

endfunction

if 0
  purpose
    choose author data via command-line input
  usage
    let a_data = projs#author#select()
  call tree
    called by
      projs#insert#cmt_author
endif

function! projs#author#select ()
  let ids = projs#author#ids()

  let rootid = projs#rootid()

  call base#varset('this',ids)

  let author_id = ''
  while !len(author_id)
    let author_id = input( printf('[rootid: %s] author_id: ',rootid),'','custom,base#complete#this')
  endw

  let author = projs#author#get({ 'a_id' : author_id })
  let author = input(printf('[rootid: %s] author: ',rootid),author)

  let a_data = {
      \ 'a'    : author,
      \ 'a_id' : author_id,
      \ }
  return a_data

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
