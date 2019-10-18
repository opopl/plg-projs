
"Usage:
"		call projs#pdf#view ()
"		call projs#pdf#view (proj)
"
"Used by:
"		PrjPdfView
"
"		PrjAct pdf_view
"		projs#action#pdf_view

function! projs#pdf#view (...)

	let proj    = get(a:000,0,projs#proj#name())

	let pdffile = projs#pdf#path(proj)
	let size = base#file#size(pdffile)

	if !filereadable(pdffile)
		call base#warn({ 'text' : 'PDF file NOT READABLE!', 'prefix' : 'projs#pdf#view'})
		return
	endif

	if !size
		call base#warn({ 'text' : 'PDF file ZERO SIZE!', 'prefix' : 'projs#pdf#view'})
		return
	endif

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

function! projs#pdf#path (...)
	let proj    = get(a:000,0,projs#proj#name())

	let pdffin  = projs#varget('pdffin','')
	let pdffile = base#file#catfile([ pdffin, proj . '.pdf' ])

	return pdffile
endfunction

function! projs#pdf#delete (...)
	let pdffile = projs#pdf#path(proj)

endfunction

