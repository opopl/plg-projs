
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

	let map_comps = {
			\	'author_id' : projs#author#ids(),
			\	}
	let comps = get(map_comps,col,[])

	call base#varset('this',comps)
  let new_val = input(printf('[ "%s" column ] new value: ',col), val, 'custom,base#complete#this')

  let dbfile = projs#db#file()
  let xmlfile =  projs#xmlfile()

	call projs#db#update_col({ 
		\	'col'    : col,
		\	'val'    : new_val,
		\	'proj'   : proj,
		\	'sec'    : sec,
		\	'prompt' : 1,
		\	'dbfile' : dbfile,
		\	})
	call base#rdw_printf([ 'Updated column: %s => %s', col, new_val ],'MoreMsg')

	call projs#xml#update_col({ 
		\	'col'     : col,
		\	'val'     : new_val,
		\	'proj'    : proj,
		\	'sec'     : sec,
		\	'xmlfile' : xmlfile,
		\	})
  
endfunction
