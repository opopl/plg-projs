
function! projs#pdf#view (...)

	let proj    = projs#proj#name()
	let pdffin  = projs#var('pdffin')
	let pdffile = base#file#catfile([ pdffin, proj . '.pdf' ])

  let viewer  = base#exefile#path('evince')

  if filereadable(pdffile)
     let ec= 'silent! !start '.viewer.' '.pdffile
     exe ec
     redraw!
  endif
endfunction
