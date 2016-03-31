
function! projs#sec#rename (new)
	let old = projs#proj#secname()

	let oldf = projs#secfile(old)
	let newf = projs#secfile(a:new)

	call rename(oldf,newf)

	let lines = readfile(newf)

	let nlines=[]
	let pat = '^\(%%file\s\+f_\)\(\w\+\)\s\+$'
	for line in lines
		if line =~ pat
			let line = substitute(line,pat,'\1'.a:new,'g')
		endif

		call add(nlines,line)
	endfor

	call writefile(nlines,newf)

	call projs#proj#secnames()
	
endfunction

function! projs#sec#remove (...)
	if a:0
		let sec = a:1
	else
		let sec = projs#proj#secname()
	endif
	
endfunction
