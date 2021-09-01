
if 0
  call tree
    called by
      projs#db_cmd#sec_add_tags
endif

function! projs#db#sec#add_tags ()
  let msg_a = [
    \  "Select proj: ",  
    \  ]
  let msg  = join(msg_a,"\n")
  let proj = base#input_we(msg,'',{ 
    \ 'complete' : 'custom,projs#complete' 
    \ })

  call projs#proj#name(proj)
 
  let secs = projs#db#secnames({ 'proj' : proj })

  let data = []
  for sec in sort(secs)
    let tags_a = projs#db#tags_get({ 'sec' : sec, 'proj' : proj })
    let tags = join(tags_a, ',')
    let r = { 
      \ 'sec'  : sec,
      \ 'tags' : tags
      \ }
    call add(data, r)
  endfor

  let lines = pymy#data#tabulate({
    \ 'data_h'    : data,
    \ 'headers'   : [ 'sec','tags' ],
    \ })
  call insert(lines,[ 'List of Sections' ])

  let cmds_after = [ 
    \ 'resize99',
    \ 'vnoremap <silent><buffer> u :call projs#db_cmd#sec_add_tags#update()<CR>',
    \ 'vnoremap <silent><buffer> v :call projs#db_cmd#sec_add_tags#view()<CR>',
    \ ]

  let stl_add = [
      \  '[ %3* u - update %4* v - view %0* ]'  
      \  ]

  call base#buf#open_split({ 
    \ 'lines'        : lines,
    \ 'cmds_after'   : cmds_after,
    \ 'stl_add'      : stl_add,
    \ })

endfunction

if 0
  Call tree
    called by
      projs#db_cmd#sec_remove
endif

function! projs#db#sec#remove (...)
  let ref = get(a:000,0,{})
  
  let proj = projs#proj#name()

  let sec = get(ref,'sec','')

  let q = printf('DELETE FROM projs WHERE proj = ? AND sec = ?')
  let p = [ proj, sec ]

  let [ rows_h, cols ] = pymy#sqlite#query({
    \ 'dbfile' : projs#db#file(),
    \ 'q'      : q,
    \ 'p'      : p,
    \ })

endfunction
