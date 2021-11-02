
function! projs#author#fb_id#list_db ()
  let dbfile = base#qw#catpath('html_root','h.db')
  
  let q = 'SELECT DISTINCT fb_id FROM auth_details ORDER BY fb_id ASC'
  let p = []
  
  let ids = pymy#sqlite#query_as_list({
    \ 'dbfile' : dbfile,
    \ 'p'      : p,
    \ 'q'      : q,
    \ })
  return ids

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
