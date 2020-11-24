
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

function! projs#util#ii_prefix_from_url (...)
  let ref = get(a:000,0,{})

  let url    = get(ref,'url','')
  let prompt = get(ref,'prompt',0)

  let struct = base#url#struct(url)
  let host   = get(struct,'host','')

  let pref = ''

  let file_pats = join([ projs#root(), 'data', 'dict', 'site_patterns.i.dat' ], )
  if !filereadable(file_pats)
    return pref
  endif

  let pats = base#readdict({ 'file' : file_pats })

  for pat in keys(pats)
    if host =~ pat
      let pref = get(pats,pat,'')
      if pat == 'facebook.com'
      endif
      break
    endif
  endfor
  return pref

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


