
"""projs_proj_name

function! projs#proj#name (...)

	if a:0
		let proj = a:1
		call projs#var('proj',proj)
	else
		let proj = projs#var('proj')
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

	call projs#proj#secnames()
endfunction

function! projs#proj#filesact (...)
 let s  = ''
 let s .= ' list'
 let s .= ' view'
 let acts = base#qwsort(s)

 if a:0
	let act = a:1
 else
	let act = base#getfromchoosedialog({ 
		 	\ 'list'        : acts,
		 	\ 'startopt'    : 'regular',
		 	\ 'header'      : "Available acts are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose act by number: ",
		 	\ })
		
 endif

 let proj = projs#proj#name()

 if act == 'list'
	call projs#proj#listfiles()
 elseif act == 'view'
	let extstr = input('File extensions:'."\n",'tex bib vim')
	let exts = base#qwsort(extstr)

	let pfiles = projs#proj#files({ "proj" : proj, 'exts' : exts }) 

	let pfile = base#getfromchoosedialog({ 
		 	\ 'list'        : pfiles,
		 	\ 'startopt'    : 'regular',
		 	\ 'header'      : "Available project files are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose a project file by number: ",
		 	\ })
	let pfile = projs#path([pfile])

	call base#fileopen(pfile)

 endif

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

	let files=[]

	if !strlen(proj) | return files | endif

	let exts = base#qw('tex vim dat')
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
	let pat = '^'.proj.'\.\(.*\).*\.tex$'
	for pfile in pfiles
		if ( pfile =~ pat )
			let sec = substitute(pfile,pat,'\1','g')
			call add(secnames,sec)
		endif
	endfor

 	call projs#var('secnames',secnames)
	call projs#proj#secnamesall()

	return secnames
	
endfunction

function! projs#proj#secnamesall (...)

	let sall = projs#var('secnames')
	call extend(sall,projs#var('secnamesbase'))
	let sall = sort(base#uniq(sall))

 	call projs#var('secnamesall',sall)

	return sall

endfunction
"
"""projs_proj_listfiles

" list existing files belonging to the project
" 	being selected
"
function! projs#proj#listfiles (...)
	let proj = projs#proj#name()

	let extstr = input('File extensions:'."\n",'tex bib vim')
	let exts = base#qwsort(extstr)

	let pfiles = projs#proj#files({ "proj" : proj, 'exts' : exts }) 

	echo "\n".'--- List of project files ---'
	for file in pfiles
	  echo file
	endfor
	echo '-----------------------------'
	
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

 let opt = 'latexmk'
 if projs#varexists('prjmake_opt')
 	let opt = projs#var('prjmake_opt')
 end
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

function! projs#proj#gitcmds (...)
	let cmds =  projs#varget('gitcmds',[])

	return cmds
endfunction

" call projs#proj#git ('add')
" call projs#proj#git ('rm')

function! projs#proj#git (...)
	let proj = projs#proj#name()

	call projs#rootcd()

	if a:0
		let cmd = a:1
	else
		let cmds = projs#proj#gitcmds()
		let start = get(cmds,0,'')

		let cmd = base#getfromchoosedialog({ 
		 	\ 'list'        : cmds,
		 	\ 'startopt'    : start,
		 	\ 'header'      : "Available git cmds are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose git cmd by number: ",
		 	\ })
	endif

	let files = projs#proj#files()
	echo files

endfunction

function! projs#proj#git_add ()
  let texfiles=projs#varget('texfiles',[])

  let newopts=projs#varget('PrjNew_opts',{})

  let git_add = get(newopts,'git_add',0)
  let git_add = input('Add each new file to git? (1/0)',git_add)

  if git_add
         for file in values(texfiles)
             if filereadable(file)
                if ! base#sys("git add " . file )
                    return 0
                endif
             endif
         endfor
   endif

        
endfunction

 
