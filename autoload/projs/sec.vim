
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
			\ "cmds"    : [ 'rm ' . secfile_u . ' -f'],
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

function! projs#sec#onload (sec)
	return
	let sec=a:sec
	call projs#sec#add(sec)

endfunction

function! projs#sec#add (sec)
	let sec   = a:sec

	let sfile = projs#secfile(sec)
	let sfile = fnamemodify(sfile,':p:t')

	let pfiles =	projs#proj#files()
	if !base#inlist(sfile,pfiles)
			call add(pfiles,sfile)

			let f_listfiles=projs#secfile('_dat_files_')
			call base#file#write_lines({ 
				\	'lines' : pfiles, 
				\	'file'  : f_listfiles, 
				\})
	endif

	if !projs#sec#exists(sec)
		let secnames    = base#varget('projs_secnames',[])
		let secnamesall = base#varget('projs_secnamesall',[])

		call add(secnames,sec)
		call add(secnamesall,sec)

		let secnamesall = base#uniq(secnamesall)
		let secnames    = base#uniq(secnames)
	endif
	
endfunction

function! projs#sec#exists (...)
	let sec = get(a:000,0,'')
	let secnamesall = copy(base#varget('projs_secnamesall',[]))

	return base#inlist(sec,secnamesall)

endfunction
