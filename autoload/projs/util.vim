
function! projs#util#month_number (...)
  let month = get(a:000,0,'')

  let maps = base#varget('projs_maps_month_num',{})
  let num  = get(maps,month,'')
  return num
  
endfunction

if 0
  call tree
    called by
      projs#insert#ii_url
endif

function! projs#util#ii_data_from_url (...)
  let ref = get(a:000,0,{})

  let url    = get(ref,'url','')
  let prompt = get(ref,'prompt',0)

  let struct = base#url#struct(url)
  let host   = get(struct,'host','')

  let pref      = ''
  let author_id = ''

  let pats = projs#data#dict({ 'id' : 'site_patterns' })

  for pat in keys(pats)
    if host =~ pat
      let pref = get(pats,pat,'')
      if pat == 'facebook.com'
        let fb_data   = projs#url#fb#data({ 'url' : url })

        let author_id = get(fb_data,'author_id','')
        if len(author_id)
          let pref .=  printf('.%s',author_id)
        endif
      endif
      break
    endif
  endfor

  return { 
    \ 'pref'      : pref,
    \ 'author_id' : author_id,
    \ }

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


