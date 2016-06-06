
function! projs#pdf#view (...)
	let proj   = projs#proj#name()
	let pdffin = projs#var('pdffin')
	let pdffile   = base#file#catfile([ pdffin, proj . '.pdf' ])

    let viewer = base#fpath('evince')
    echo pdffile
    echo viewer

    if filereadable(pdffile)
        "call system("start ". viewer." ".pdffile)
        let ec= 'silent! !start '.viewer.' '.pdffile
        exe ec
        redraw!
        "exe 'setlocal makeprg='.viewer.'\ '.pdffile
        "silent make!
    endif
endfunction
