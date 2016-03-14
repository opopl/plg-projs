
"""projs_proj_name

function! projs#proj#name ()
	let proj = projs#var('proj')
	return proj
endfunction

function! projs#proj#secname ()
	let sec = projs#var('secname')
	return sec
endfunction

function! projs#proj#reset (...)
	if a:0
		let proj = a:1
	endif

	call projs#var('proj',proj)
endfunction

function! projs#proj#files (...)
	let proj = projs#proj#name()
	if a:0
		let proj = a:1
	endif

	let root   = projs#root()
	let picdir = projs#path([ 'pics' , proj ])
	let dirs   = [ root ]

	if isdirectory(picdir)
		call add(dirs,picdir)
	endif

	let files = base#find({
	  \   'dirs'       :  dirs          ,
	  \   'relpath'    :  1             ,
	  \   'pat'        :  '^'.proj.'\.' ,
	  \   })

	return files
	
endfunction

function! projs#proj#secnames (...)
	let proj = projs#proj#name()
	if a:0 | let proj = a:1 | endif

	let root   = projs#root()

	let pfiles = projs#proj#files(proj) 

	let secnames=[]
	let pat = '^'.proj.'\.\(\w\+\).*\.tex$'
	for pfile in pfiles
		if ( pfile =~ pat )
			let sec = substitute(pfile,pat,'\1','g')
			call add(secnames,sec)
		endif
	endfor

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

	let pfiles = projs#proj#files(proj) 

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

 let pfiles = projs#proj#files(proj)

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
		   		\	]

		endif
	
	   if ! base#sys( cmds )
	 		return 0
	   endif
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

 let opts={ 
    \ 'steps' : '_all_', 
    \ 'mode'  : 'nonstopmode',
    \ 'proj'  : oldproj,
    \ }

 if a:0
   call extend(opts,a:1)
 endif

 let g:proj  = opts.proj

 call projs#var('texmode',opts.mode)

 let i=0
 let mks=projs#var('makesteps')
 if opts.steps == '_all_'
   let opts.steps=join(mks,',')
 endif

 echohl CursorLineNr
 echo 'Starting PrjMake ... '
 echohl Question
 echo ' Steps: ' . opts.steps
 echohl None

 for step in split(opts.steps,',')
    let fun='projs#makesteps#' . step
    if exists("*" . fun)
      exe 'call ' . fun . '()'
    endif
 endfor

 call projs#proj#reset(oldproj)
	
endfunction
 







