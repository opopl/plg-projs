
function! projs#author#fb_id#list_db ()
  let dbfile = projs#db#file()
  
  let q = 'SELECT DISTINCT fb_id FROM auth_details ORDER BY fb_id ASC'
  let p = []
  
  let ids = pymy#sqlite#query_as_list({
    \ 'dbfile' : dbfile,
    \ 'p'      : p,
    \ 'q'      : q,
    \ })
  return ids

endfunction

function! projs#author#fb_id#get_dat (...)
  let ref = get(a:000,0,{})

  let author_id = get(ref,'author_id','')
  if !len(author_id) | return [] | endif
  let fb_ids = []

  let fb_authors   = projs#data#dict({ 'id' : 'fb_authors' })
  for [fb_id, a_id] in items(fb_authors)
     if a_id == author_id
       call add(fb_ids, fb_id)
     endif
  endfor

  return fb_ids

endfunction

function! projs#author#fb_id#select_db (...)
  let ref = get(a:000,0,{})

  let lst = projs#author#fb_id#list_db()
  let r = { 
    \ 'list'  : lst,
    \ 'thing' : 'fb_id',
    \ }

  let fb_id = base#inpx#ctl(r) 

  return fb_id
  
endfunction
