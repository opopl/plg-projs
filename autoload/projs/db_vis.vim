
if 0
  used in:
    projs#db_cmd#buf_data
endif

function! projs#db_vis#update ()
  let lines = base#vim#visual_selection()

  for line in lines
    let col = matchstr(line,'^\s*\d\+\s\+\zs\(\w\+\)\ze.*$')
    let val = matchstr(line,'^\s*\d\+\s\+\w\+\s*\zs.*\ze$')
  endfor

  let sec  = projs#proj#secname()
  let proj = projs#proj#name()
  let root = projs#root()

  let file = projs#sec#file(sec)

  let new_val = input(printf('[ "%s" column ] new value: ',col), val)

  let dbfile = projs#db#file()
  
  let t = "projs"
  let h = {
    \  col : new_val,
    \  }

  if col == 'url'
    let url = new_val

    let b:url = url

    let do_insert = input('Insert url lines? (1/0): ',1)
    if do_insert
      call projs#sec#insert_url({ 
        \ 'url' : url, 
        \ 'sec' : sec })
    endif
  endif

  let w = {
      \  'sec'  : sec,
      \  'proj' : proj,
      \  }
  
  let ref = {
    \ "dbfile" : dbfile,
    \ "t"      : t,
    \ "h"      : h,
    \ "w"      : w
    \ }
    
  call pymy#sqlite#update_hash(ref)

  if col == 'tags'
    call projs#db_cmd#fill_tags()
  endif

  
endfunction
