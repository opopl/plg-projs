
function! projs#author#id#select_db (...)
  let ref = get(a:000,0,{})

  let author_id = get(ref,'author_id','')

  let ids = projs#author#id#list_db()

  let rootid = projs#rootid()

  call base#varset('this',ids)

  while(1)
    let author_id = input( printf('[Database][rootid: %s] author_id: ',rootid),author_id,'custom,base#complete#this')
    if len(author_id)
      break
    endif
  endw

  return author_id
  
endfunction

function! projs#author#id#in_fs (author_id)
  let ids_fs = projs#author#id#list_fs()

  return base#inlist(a:author_id,ids_fs) ? 1 : 0
endfunction

function! projs#author#id#in_db (author_id)
  let ids_db = projs#author#id#list_db()

  return base#inlist(a:author_id,ids_db) ? 1 : 0
endfunction

function! projs#author#id#list_fs ()
  let hash = projs#author#hash()
  let ids = keys(hash)
  let ids = base#uniq(ids)

  return ids
endfunction

function! projs#author#id#list_db ()
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