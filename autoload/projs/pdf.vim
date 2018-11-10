
function! projs#pdf#view (...)

	let proj    = get(a:000,0,projs#proj#name())

	let pdffin  = projs#var('pdffin')
	let pdffile = base#file#catfile([ pdffin, proj . '.pdf' ])

  let viewer  = base#exefile#path('evince')

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
