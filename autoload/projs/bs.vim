
function! projs#bs#cmd (...)
  let act  = get(a:000,0,'')

  let acts = base#varget('projs_opts_BS',[])

  let proj = projs#proj#name()

  call projs#bld#make_secs()

  let fmt_sub = 'projs#bs#cmd#%s'
  let front = [
      \ 'Current project:' , "\t" . proj,
      \ 'Possible BLD actions: ' 
      \ ]
  let desc = base#varget('projs_desc_BLD',{})

  let Fc = projs#fc#match_proj({ 'proj' : proj })
  
  call base#util#split_acts({
    \ 'act'     : act,
    \ 'acts'    : acts,
    \ 'desc'    : desc,
    \ 'front'   : front,
    \ 'fmt_sub' : fmt_sub,
    \ 'Fc'      : Fc,
    \ })
  
endfunction

function! projs#bs#site (...)
  let site = get(a:000,0,'')

  let bs_data = projs#bs#data()
  if len(site)
    call extend(bs_data,{ 'site' : site })
    call projs#bs#data(bs_data)
  else
    let site = get(bs_data,'site','')
  endif

  return site
endfunction

function! projs#bs#data (...)
  let ref = get(a:000,0,{})

  if len(ref)
    call base#varset('projs_bs_data',ref)
  endif
  let bs_data = base#varget('projs_bs_data',{})
  return bs_data

endfunction

function! projs#bs#select_site (...)
  let ref = get(a:000,0,{})

  let bs_data = projs#bs#data()

  let sites   = get(bs_data,'sites',[])
  let sites   = copy(sites)

  let sites   = get(ref,'sites',sites)

  let pat = '^\zs\w\+\ze\(\..*\|\)$'
  let pieces = []

  let site_j = ''

  while 1
    let choice = ''
    let choices = {}
    for site in sites
      let choice = matchstr(site, pat )
      call extend(choices,{ choice : 1 })
    endfor

    call base#varset('this',keys(choices))

    let msg_s = len(pieces) ?  "\n" . site_j . "\n" : ''
    let msg_i = printf('%s site: ',msg_s)

    let piece = base#input_we(msg_i,'',{ 'complete' : 'custom,base#complete#this' })

    call add(pieces, piece)
    let site_j = join(pieces, ".")

    call filter(sites,printf('v:val =~ "^%s"',piece))

    let n = []
    for site in sites
      let site = substitute(site,printf('^%s[\.]*', piece),'','g')
      if len(site)
        call add(n,site)
      endif
    endfor
    let sites = n

    if !len(sites)
      break
    endif
  endw

  return site_j

endfunction

function! projs#bs#db_file (...)
  let bs_data = projs#bs#data()

  let db_file = base#qw#catpath('html_root','h.db')
  let db_file = get(bs_data,'db_file',db_file)

  return db_file

endfunction

if 0
  called by
    projs#bs#cmd#site_view
endif

function! projs#bs#load_site_files (...)
  let ref = get(a:000,0,{})

  let exts = get(ref,'exts',[])
  let site = get(ref,'site','')

  call base#rdw(printf('%s',site))

  let bs_data = projs#bs#data()

  let pieces = split(site,'\.')

  let stem = remove(pieces,-1)
  let site_dir = base#qw#catpath('p_sr','scrape bs in sites ' . join(pieces, ' '))
  let ff = base#find({ 
    \  "dirs"    : [site_dir],
    \  "exts"    : base#qw('py yaml'),
    \  "cwd"     : 1,
    \  "relpath" : 0,
    \  "subdirs" : 1,
    \  "pat"     : '^' . stem,
    \  })

  call extend(bs_data,{ 'site' : site })
  call projs#bs#data(bs_data)

  let s:obj = {  }
  function! s:obj.init (...) dict
    let b:projs_bs_data = projs#bs#data()

    StatusLine projs_bs
  endfunction
  
  let Fc = s:obj.init

  call chdir(site_dir)
  call base#fileopen({ 
    \  'files'    : ff,
    \  'load_buf' : 1,
    \  'Fc'       : Fc,
    \  'action'   : 'vsplit',
    \  })

  call base#rdw(printf('SITE: %s',site))


endfunction

