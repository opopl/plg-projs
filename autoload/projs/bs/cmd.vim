
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

  let pat = '^\zs\w\+\ze\(\..*\|\)$'
  let msg = []

  while 1
    echo sites

    let choice = ''
    let choices = {}
    for site in sites
      let choice = matchstr(site, pat )
      call extend(choices,{ choice : 1 })
    endfor

    call base#varset('this',keys(choices))
    let msg_s = len(msg) ?  "\n" . join(msg, ".") . "\n" : ''
    let piece = input(printf('%s site: ',msg_s),'','custom,base#complete#this')

    call add(msg, piece)

    call filter(sites,printf('v:val =~ "^%s"',piece))

    let n = []
    for site in sites
      let site = substitute(site,printf('^%s\.', piece),'','g')
      call add(n,site)
    endfor
    let sites = n

    if !len(sites)
      break
    endif
  endw

  echo choices

endfunction

function! projs#bs#cmd#init ()
  let bs_dir = base#qw#catpath('p_sr','scrape bs')

  call chdir(bs_dir)
  let cmd = 'bs.py -p list_sites -y mix.yaml'

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
