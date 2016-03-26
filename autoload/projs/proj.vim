
"""projs_proj_name

function! projs#proj#name (...)

	if a:0
		let proj = a:1
		call projs#var('proj',proj)
	else
		let proj = projs#var('proj')
		"if !strlen(proj)
			"let proj = projs#selectproject()
		"endif
	endif
	return proj
endfunction

function! projs#proj#secname (...)

	if a:0
		let sec = a:1
		call projs#var('secname',sec)
	else
		let sec = projs#var('secname')
	endif
	return sec
endfunction

function! projs#proj#reset (...)
	if a:0
		let proj = a:1
	endif

	call projs#var('proj',proj)
endfunction

"let files = projs#proj#files ({ "proj" : proj })
"let files = projs#proj#files ({ "exts" : ["tex"]})
"
"let files = projs#proj#files ()

function! projs#proj#files (...)
	let ref = {}
	if a:0 | let ref = a:1 | endif

	let proj = projs#proj#name()
	let proj = get(ref,'proj',proj)

	let exts = []
	let exts = get(ref,'exts',exts)

	let prompt = get(ref,'prompt',0)

	let root   = projs#root()
	let picdir = projs#path([ 'pics' , proj ])
	let dirs   = [ root ]

	if isdirectory(picdir)
		call add(dirs,picdir)
	endif

	let fref = {
			\   'dirs'       :  dirs          ,
			\   'relpath'    :  1             ,
			\   'pat'        :  '^'.proj.'\.' ,
			\   'exts'       :  exts,
			\   }
	let files = base#find(fref)

	let dirs = base#qw('joins builds')
	let dirs = get(ref,'exclude_dirs',dirs)
	if len(dirs)
		for dir in dirs
			call filter(files,"v:val !~ '^".dir."'")
		endfor
	endif

	return files
	
endfunction

" Calculate available section names for
" 	the current project

" projs#proj#secnames ()
" projs#proj#secnames (proj)

function! projs#proj#secnames (...)
	let proj = projs#proj#name()
	if a:0 | let proj = a:1 | endif

	let root   = projs#root()

 	let pfiles = projs#proj#files({ "proj" : proj })

	let secnames=[]
	let pat = '^'.proj.'\.\(\w\+\).*\.tex$'
	for pfile in pfiles
		if ( pfile =~ pat )
			let sec = substitute(pfile,pat,'\1','g')
			call add(secnames,sec)
		endif
	endfor

 	call projs#var('secnames',secnames)

	return secnames
	
endfunction
"
"""projs_proj_listfiles

" list existing files belonging to the project
" 	being selected
"
function! projs#proj#listfiles (...)
	let proj = projs#proj#name()
	if a:0
		let proj = a:1
	endif

	let pfiles = projs#proj#files({ "proj" : proj }) 

	for file in pfiles
	  echo file
	endfor
	
endfunction

function! projs#proj#listsecnames (...)
	let proj = projs#proj#name()
	if a:0
		let proj = a:1
	endif

	let secnames = projs#proj#secnames(proj) 

	for sec in secnames
	  echo sec
	endfor
	
endfunction

function! projs#proj#removefromdat(proj)

 call base#echo({ 'text' : 'Removing project from PROJS dat file...'})
 let proj=a:proj

 "" remove proj from PROJS datfile
 let dfile = projs#path(['PROJS.i.dat'])
 let lines = readfile(dfile)
 let newlines=[]

 let add = 1
 for line in lines
	if line =~ '^\s*#'
		call add(newlines,line)
		continue
	endif

	let p = split(line," ")
	call filter(p,"v:val != proj")

	if len(p)
		let line = join(p," ")
		call add(newlines,line)
	endif

 endfor

 call writefile(newlines,dfile)

endfunction

function! projs#proj#remove(proj)

 let ok     = 0
 let proj   = a:proj
 let prefix = '(projs#proj#remove) '

 call base#echoprefix(prefix)

 if ! projs#ex(proj)
	call base#warn({ 
		\ 'text'   : 'Input project does not exist:  ' . proj,
	    \ 	})
	return 1
 endif

 let projs = projs#list()

 """ remove proj from projs
 call filter(projs,"v:val != proj") 

 call projs#proj#removefromdat(proj)

 let pfiles = projs#proj#files({ "proj" : proj })
 call map(pfiles,'projs#path([ v:val ])')

 for file in pfiles
	 if filereadable(file)
		echo 'Removing file: ' . file

		if has('unix')
			let cmds=[ 
				\	"git reset HEAD " . file . ' || echo $?',
				\	"git checkout -- " . file . ' || echo $?',
		   		\	"git rm " . file . ' -f || rm -f ' . file,
		   		\	]
		else
			let cmds=[ 
				\	"git reset HEAD " . file . '',
				\	"git checkout -- " . file . '',
		   		\	"git rm " . file . ' -f',
		   		\	"del " . file,
		   		\	]

		endif

	   	call base#sys({
			\	"cmds"   : cmds   ,
			\	"prompt" : 0      ,
			\	"skip_errors" : 1 ,
			\	})
 	 endif
 endfor

 call base#echoredraw('Project removed: ' . proj)

 let ok = 1

 call base#echoprefixold()
 
 return ok

endfunction


function! projs#proj#make (...)

 call projs#rootcd()

 let oldproj = projs#proj#name()

 let opt = 'single_run'
 if a:0
	let opt = a:1
 endif

 call projs#var('texmode','nonstopmode')

 echohl CursorLineNr
 echo 'Starting PrjMake ... '
 echohl Question
 echo ' Selected option: ' . opt
 echohl None

 call projs#build#run(opt)
	
endfunction
 
