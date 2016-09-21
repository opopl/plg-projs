
function! projs#action#tags_replace ()
	let files = projs#proj#files()
	let pdir = projs#root()

	for f in files
		let p = base#file#catfile([ pdir, f ])
		if !filereadable(p)
			continue
		endif
		echo p

		let lines  = readfile(p)
		let nlines = []

		let pat    = '^%%file\s\+f_\(.*\)$'

		for l in lines
			if l =~ pat
				let l = substitute(l,pat,'%%file \1','g')
			endif
			call add(nlines,l)
		endfor

		call writefile(nlines,p)
	endfor

	
endfunction
