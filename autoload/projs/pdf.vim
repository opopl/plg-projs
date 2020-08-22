
"Usage:
"   call projs#pdf#view ()
"   call projs#pdf#view (proj)
"
"Used by:
"   PrjPdfView
"
"   PrjAct pdf_view
"   projs#action#pdf_view

function! projs#pdf#view (...)

  let proj    = get(a:000,0,projs#proj#name())

  let pdffile = projs#pdf#path(proj)

  if !filereadable(pdffile)
    let msg = 'PDF file NOT READABLE!'
    call base#warn({ 'rdw' : 1, 'text' : msg, 'prefix' : 'projs#pdf#view'})
    return
  endif

  let size = base#file#size(pdffile)

  if !size
    let msg = 'PDF file ZERO SIZE!'
    call base#warn({ 'text' : msg , 'prefix' : 'projs#pdf#view', 'rdw' : 1 })
    return
  endif

  let viewer  = base#exefile#path('evince')
  let viewer  = base#exefile#path('okular')

  if filereadable(pdffile)
    if has('win32')
     let ec= 'silent! !start '.viewer.' '.pdffile
    else  
     let ec= 'silent! !'.viewer.' '.pdffile . ' &'
    endif

    exe ec
    redraw!
  endif
endfunction

if 0
  Usage
    let pdf = projs#pdf#path('aa')
    let pdf = projs#pdf#path('aa','pwg')
  Call tree
    Called by
      projs#pdf#view
      projs#pdf#delete
endif

function! projs#pdf#path (...)
  let proj    = get(a:000,0,projs#proj#name())

  let qw = get(a:000,1,'')

  let pdffin  = projs#varget('pdffin','')

  let a = [ pdffin, projs#rootid() ]
  call extend(a,split(qw,' '))
  call extend(a,[ printf('%s.pdf',proj) ])

  let pdffile = base#file#catfile(a)

  return pdffile
endfunction

function! projs#pdf#delete (...)
  let proj    = get(a:000,0,projs#proj#name())

  let pdffile = projs#pdf#path(proj)

  if !filereadable(pdffile)
    redraw!
    echohl Question
    echo 'No PDF file! Nothing to delete.'
    echohl None
    return
  endif

  let yn = input('delete PDF file? (1/0): ', 1)
  if !yn | return | endif

  call delete(pdffile)
  if !filereadable(pdffile)
    redraw!
    echohl MoreMsg
    echo 'PDF file has been deleted.'
    echohl None
  endif

endfunction

