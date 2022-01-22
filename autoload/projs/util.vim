
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

  if site == 'com.us.facebook'
     let fb_data   = projs#url#fb#data({
       \ 'url'    : url,
       \ 'prompt' : prompt,
       \ })

     let author_id = get(fb_data,'author_id','')
     if len(author_id)
       let pref .=  printf('.%s',author_id)
     endif

  elseif site == 'news.ru.yandex.zen'
    let yz_authors = projs#data#dict({ 'id' : 'yz_authors' })
    let yz_ids = keys(yz_authors)
    let yz_id = matchstr(path, '^/media/id/\zs[^/]*\ze' )
    let author_id = base#list#has(yz_ids, yz_id) ? get(yz_authors, yz_id, '') : ''
    if !len(author_id)
      let author_id = projs#author#select_id({ 'author_id' : 'yz.' })

      let author_ids_db   = projs#author#ids_db()
      let author_ids_dict = projs#author#ids()

      # there's no author_id, need to add it
      if !base#list#has(author_ids_dict, author_id)
        if base#list#has(author_ids_db, author_id)
           let author_name = base#input_we('Author name: ','')

           call projs#data#dict#update({
              \ 'id'  : 'authors',
              \ 'upd' : { author_id : author_name },
              \ })
        endif

      call projs#data#dict#update({
        \ 'id'  : 'yz_authors',
        \ 'upd' : { yz_id : author_id },
        \ })

    endif

    debug echo 1

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


