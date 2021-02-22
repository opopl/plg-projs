
function! projs#bs#cmd#run ()
  
endfunction

"""bs_site_view
function! projs#bs#cmd#site_view ()
  let bs_data = base#varget('projs_bs_data',{})
  let bs_data = bs_data

  if !len(bs_data)
    call base#rdwe('No BS data! aborting')
    return 
  endif

  let sites = get(bs_data,'sites',[])
  let sites = copy(sites)

  if !len(sites)
    call base#rdwe('No SITES! aborting')
    return 
  endif

  let site = projs#bs#select_site()

  call projs#bs#load_site_files({ 
    \ 'site' : site,
    \ 'exts' : base#qw('py yaml'),
    \ })

endfunction

function! projs#bs#cmd#yaml_site_load ()

endfunction

"""bs_db_query
function! projs#bs#cmd#db_query ()

  let db_file = projs#bs#db_file()

  let msg_a = [
    \  printf("db_file: %s", db_file),  
    \  " ",  
    \  "SQLITE query: ",  
    \  ]
  let msg = join(msg_a,"\n")
  let q =  base#input_hist(msg,'','projs_bs_sql')
  let p = []

  let lines = pymy#sqlite#query_screen({
    \  'dbfile' : db_file,
    \  'p'      : p,
    \  'q'      : q,
    \  })

  call base#buf#open_split({ 
        \ 'lines' : lines 
        \ })

endfunction

function! projs#bs#cmd#db_page_act ()

endfunction

function! projs#bs#cmd#info ()
  let info = [ 'BS INFO', ' ' ]

  let site = projs#bs#site()
  let rid  = projs#bs#rid()

  call add(info,printf('site: %s',site))
  call add(info,printf('rid: %s',rid))

  call base#buf#open_split({ 
    \ 'lines' : info 
    \ })

endfunction

function! projs#bs#cmd#rid_grep ()
	let rid = projs#bs#rid_select()

	let expr = base#input_hist('GREP: ','','hist_bs_grep')

	let cmd  = printf('bs.py -c html_parse -i cache.html -g "%s"',expr)

	let env = {
		\ 'cmd' : cmd,
		\ 'rid' : rid,
		\	}

	function env.get(temp_file) dict
		let temp_file = a:temp_file
		let code      = self.return_code
	
		if filereadable(a:temp_file)
			let out = readfile(a:temp_file)
			call base#buf#open_split({ 'lines' : out })
		endif
	endfunction
	
	call asc#run({ 
		\	'cmd'  : cmd,
		\	'path' : projs#bs#rid_dir(rid),
		\	'Fn'   : asc#tab_restore(env)
		\	})

endfunction

function! projs#bs#cmd#rid_terminal ()
	call projs#bs#cmd#rid_cd ()
	terminal

endfunction

function! projs#bs#cmd#rid_cd ()
	let bs_data = base#varget('projs_bs_data',{})

	let rid = projs#bs#rid_select()

	let rid_dir = projs#bs#rid_dir(rid)

	call base#cd(rid_dir)

endfunction

function! projs#bs#cmd#init ()
  let bs_dir = base#qw#catpath('p_sr','scrape bs')

  call chdir(bs_dir)
  let cmd = 'bs.py -c run -p list_sites -y mix.yaml'

  let env = {
    \ 'cmd' : cmd,
    \ }

  function env.get(temp_file) dict
    let temp_file = a:temp_file
    let code      = self.return_code
  
    if ! filereadable(a:temp_file)
      return 1
    endif

    let out = readfile(a:temp_file)

    let type = ''
    let field = ''

    let field_values = {}
    let sites = []

    for line in out
      if !len(type)
        let list = matchlist(line, '^print_field\s\+\(\w\+\)\s\(\w\+\)\s*$' )

        if len(list)
          let field = get(list,1,'')
          let type  = get(list,2,'')

        endif

        continue
      endif

      if type == 'list'
        call add(sites,line)
      endif

    endfor

    let data = base#varget('projs_bs_data',{})
    call extend(data,{ 'sites' : sites })
    call base#varset('projs_bs_data',data)
  endfunction
  
  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })
  
endfunction
