
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
      base#url#struct

      projs#data#dict
      projs#url#fb#data
        projs#author#get
        projs#author#add_prompt
endif

function! projs#util#ii_data_from_url (...)
  let ref = get(a:000,0,{})

  let url    = get(ref,'url','')
  let prompt = get(ref,'prompt',0)

  let struct = base#url#parse(url)
  let host   = get(struct,'host','')

  let pref      = ''
  let author_id = ''

  "let pats = projs#data#dict({ 'id' : 'site_patterns' })
  let [ site, pref ] = projs#url#site#get({ 'url' : url })

  if site == 'com.us.facebook'
     let fb_data   = projs#url#fb#data({
       \ 'url'    : url,
       \ 'prompt' : prompt,
       \ })

     debug let author_id = get(fb_data,'author_id','')
     if len(author_id)
       let pref .=  printf('.%s',author_id)
     endif
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


