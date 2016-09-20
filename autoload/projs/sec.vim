
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

	let sec = projs#proj#secname()
	let sec = get(a:000,0,sec)

	let secfile   = projs#secfile(sec)
	let secfile_u = base#file#win2unix(secfile)

	if filereadable(secfile)
		call base#git({ 
			\ "cmds"    : [ 'rm ' . secfile_u ],
	  	\ "gitopts" : { "git_prompt" : 0},
			\	})
	else
		call projs#warn('Section file does not exist for: '.sec)
		return
	endif

	call base#file#delete({ 'file' : secfile })

	if !filereadable(secfile)
		call projs#echo('Section has been deleted: '.sec)
	endif

endfunction

function! projs#sec#exists (...)
	let sec = get(a:000,0,'')
	let secnames = copy(projs#varget('secnames',[]))

	call extend(secnames,projs#varget('secnamesbase',[]))

	return base#inlist(sec,secnames)

endfunction
