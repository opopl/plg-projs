

"projs#sec#rename( new,old ) 

function! projs#sec#rename (...)
	let new = get(a:000,0,'')

	let old = projs#proj#secname()
	let old = get(a:000,1,old)

	if !strlen(new)
		let new = input('[sec='.old.' ] New section name: ','','custom,projs#complete#secnames')
	endif

	let oldf = projs#secfile(old)
	let newf = projs#secfile(new)

	let oldf_base = projs#secfile_base(old)
	let newf_base = projs#secfile_base(new)

	call rename(oldf,newf)

	let lines = readfile(newf)

	let nlines = []
	let pats = {}
	call extend(pats,{ '^\(%%file\s\+\)\(\w\+\)\s*$' : '\1'.new  })
	call extend(pats,{ '^\(\\label{sec:\)'.old.'\(}\s*\)$' : '\1'.new.'\2' })
	
	for line in lines
		for [pat,subpat] in items(pats)
			if line =~ pat
				let line = substitute(line,pat,subpat,'g')
			endif
		endfor

		call add(nlines,line)
	endfor

	call writefile(nlines,newf)

 	let pfiles = projs#proj#files()
  let ex = {}
  for pfile in pfiles
    call extend(ex,{ pfile : 1 })
  endfor
  call extend(ex,{ newf_base : 1, oldf_base : 0 })

	let pfiles=[]
	for [file,infile] in items(ex)
		if infile
			call add(pfiles,file)
		endif
	endfor

  let f_listfiles = projs#secfile('_dat_files_') 

	call base#file#write_lines({ 
			\	'lines' : pfiles,
			\	'file'  : f_listfiles,
			\})

	call projs#proj#secnames()
	call base#fileopen({ 'files' : [newf]})
	
endfunction

function! projs#sec#delete (...)

	let sec = projs#proj#secname()
	let sec = get(a:000,0,sec)

	let secfile   = projs#secfile(sec)
	let secfile_u = base#file#win2unix(secfile)

	if filereadable(secfile)
		let cmd = 'git rm ' . secfile_u . ' --cached '
		let ok = base#sys({ 
			\	"cmds"         : [cmd],
			\	"split_output" : 0,
			\	"skip_errors"  : 1,
			\	})
	else
		call projs#warn('Section file does not exist for: '.sec)
		return
	endif

	let ok = base#file#delete({ 'file' : secfile })

	if ok
		call projs#echo('Section has been deleted: ' . sec)
	endif

endfunction

function! projs#sec#onload (sec)
	let sec = a:sec

	let prf = { 'prf' : 'projs#sec#onload' }
	call base#log([
		\	'sec => ' . sec,
		\	],prf)
	call projs#sec#add(sec)

	return
endfunction

"	projs#sec#add
"
"	Purpose:
"		
"	Usage:
"		call projs#sec#add (sec)
"	Returns:
"		
"
"	Call tree:
"		calls:
"			projs#proj#name
"			projs#secfile
"			projs#proj#files
"			base#file#write_lines
"			projs#sec#exists
"			projs#db#file
"		called by:
"			<++>

function! projs#sec#add (sec)
	let sec   = a:sec

	let proj = projs#proj#name()

	let sfile = projs#secfile(sec)
	let sfile = fnamemodify(sfile,':p:t')

	let pfiles =	projs#proj#files()
	if !base#inlist(sfile,pfiles)
		call add(pfiles,sfile)
	
		let f_listfiles = projs#secfile('_dat_files_')
		call base#file#write_lines({ 
			\	'lines' : pfiles, 
			\	'file'  : f_listfiles, 
			\})
	endif

	if ! projs#sec#exists(sec)
		let secnames    = base#varget('projs_secnames',[])
		let secnamesall = base#varget('projs_secnamesall',[])

		call add(secnames,sec)
		call add(secnamesall,sec)

		let secnamesall = base#uniq(secnamesall)
		let secnames    = base#uniq(secnames)
	endif

	let dbfile  = projs#db#file()
	
	let t = "projs"
	let h = {
		\	"proj"   : proj,
		\	"sec"    : sec,
		\	"file"   : sfile,
		\	"root"   : projs#root(),
		\	"rootid" : projs#rootid(),
		\	"tags"   : "",
		\	"author" : "",
		\	}
	
	let ref = {
		\ "dbfile" : dbfile,
		\ "i"      : "INSERT OR IGNORE",
		\ "t"      : t,
		\ "h"      : h,
		\ }
		
	call pymy#sqlite#insert_hash(ref)

endfunction

function! projs#sec#exists (...)
	let sec = get(a:000,0,'')

	let secnamesall = projs#proj#secnamesall ()

	return base#inlist(sec,secnamesall)

endfunction
