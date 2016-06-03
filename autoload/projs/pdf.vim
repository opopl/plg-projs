
function! projs#pdf#view (...)
	let proj   = projs#proj#name()
	let pdffin = projs#var('pdffin')
	let file   = base#file#catfile([ pdffin, proj . '.pdf' ])
endfunction
