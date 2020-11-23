
function! projs#util#month_number (...)
  let month = get(a:000,0,'')

  let maps = {
      \ 'jan' : '01',
      \ 'feb' : '02',
      \ 'mar' : '03',
      \ 'apr' : '04',
      \ 'may' : '05',
      \ 'jun' : '06',
      \ 'jul' : '07',
      \ 'aug' : '08',
      \ 'sep' : '09',
      \ 'oct' : '10',
      \ 'nov' : '11',
      \ 'dec' : '12',
      \ }
  let num = get(maps,month,'')
  return num
  
endfunction

function! projs#util#subsec (...)
  let seccmd = get(a:000,0,'')

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