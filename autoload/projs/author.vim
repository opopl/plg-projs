
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
endfunction

function! projs#author#select ()
  let ids = projs#author#ids()

  call base#varset('this',ids)
  let author_id = input('author_id: ','','custom,base#complete#this')
  let author    = projs#author#get({ 'a_id' : author_id })

  let author = input('author: ',author)

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
