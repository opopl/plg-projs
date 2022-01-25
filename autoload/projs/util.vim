
function! projs#util#month_number (...)
  let month = get(a:000,0,'')

  let maps = base#varget('projs_maps_month_num',{})
  let num  = get(maps,month,'')
  return num
  
endfunction

""cmt
if 0
  call tree
    called by
      projs#insert#ii_url
    calls
      projs#data#dict
      projs#url#fb#data
endif
""endcmt
"

if 0
  usage
    call projs#util#ii_data_from_url({ 
      \ "url"    : url,
      \ "prompt" : prompt,
      \ })
  call tree
    calls
      base#url#parse

      projs#data#dict
      projs#url#fb#data
        projs#author#get
        projs#author#add_prompt
endif

function! projs#util#ii_data_from_url (...)
  let ref = get(a:000,0,{})

  let url    = get(ref,'url','')
  let prompt = get(ref,'prompt',0)

  let u = base#url#parse(url)
  let host   = get(u,'host','')
  let path   = get(u,'path','')

  let pref      = ''
  let author_id = ''

  "let pats = projs#data#dict({ 'id' : 'site_patterns' })
  let [ site, pref ] = projs#url#site#get({ 'url' : url })

  let yfile = base#qw#catpath('plg','projs data yaml tp_data.yaml')

  let tp_data = base#yaml#parse_fs({ 'file' : yfile })

  let site2tp = get(tp_data,'site2tp',{})
  let tp_sites = keys(site2tp)

  let site_tp = get(site2tp,site,{})

  let tp_key  = get(site_tp,'tp_key','')
  let re_path = get(site_tp,'re_path','')
  let pref_sub = get(site_tp,'pref_sub',{})

"""site_fb
  if site == 'com.us.facebook'
     let fb_data   = projs#url#fb#data({
       \ 'url'    : url,
       \ 'prompt' : prompt,
       \ })

     let author_id = get(fb_data,'author_id','')
     if len(author_id)
       let pref .=  printf('.%s',author_id)
     endif

" telegram, yz
  elseif base#list#has(tp_sites, site )
    let tp_val = matchstr(path, re_path )

    debug let author_id = projs#author#find_id({
        \ 'tp_key'  : tp_key,
        \ 'tp_val'  : tp_val })

    if len(author_id)
      let pref .=  printf('.%s',author_id)
      if len(pref_sub)
        let pat  = get(pref_sub,'pat','')
        let repl = get(pref_sub,'repl','')
        if len(pat) && len(repl)
          let pref = substitute(pref,pat,repl,'g')
        endif
      endif
    endif

  " if site == ... loop
  else
    let author_id = projs#author#select_id()
  endif

  let ii_data = {
    \ 'pref'      : pref,
    \ 'author_id' : author_id,
    \ }

  return ii_data

endfunction

function! projs#util#subsec (...)
  let seccmd = get(a:000,0,'')

  let pats = base#varget('projs_maps_subsec',{})

  let maps = {
      \  'part'          : 'chapter',
      \  'chapter'       : 'section',
      \  'section'       : 'subsection',
      \  'subsection'    : 'subsubsection',
      \  'subsubsection' : 'paragraph',
      \  'paragraph'     : 'subparagraph',
      \  }
  let ss = get(maps,seccmd,'')
  return ss
endfunction


