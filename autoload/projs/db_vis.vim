
function! projs#db_vis#update ()
  let lines = base#vim#visual_selection()

  for line in lines
    let col = matchstr(line,'^\s*\d\+\s\+\zs\(\w\+\)\ze.*$')
    let val = matchstr(line,'^\s*\d\+\s\+\w\+\zs.*\ze$')
  endfor

  let sec  = projs#proj#secname()
  let proj = projs#proj#name()

  let new_val = input(printf('[ "%s" column ] new value: ',col), val)

  let dbfile = projs#db#file()
  
  let t = "projs"
  let h = {
    \  col : new_val,
    \  }

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

  
endfunction
