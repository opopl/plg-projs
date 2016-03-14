"""projs_new
function! projs#new (...)

 echo ""
 echo "This will create a new TeX project skeleton "
 echo "		in projects' root directory: " . projs#root() 
 echo ""

 let yn=input('Continue? (y/n): ','y')
 if yn != 'y'
   return 0
 endif
  
 if a:0
 	 let proj     = a:1
	 let projtype = 'regular'

 else
	 let projtype=base#getfromchoosedialog({ 
		 	\ 'list'        : projs#var('projecttypes'),
		 	\ 'startopt'    : '',
		 	\ 'header'      : "Available project types are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose a project type by number: ",
		 	\ })

 endif

 let projstruct=base#getfromchoosedialog({ 
		 	\ 'list'        : projs#var('projectstructures'),
		 	\ 'startopt'    : 'in_root',
		 	\ 'header'      : "Available project structures are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose a project structure by number: ",
		 	\ })

 call projs#rootcd()

"""projtype_regular
 if projtype == 'regular'

	 if ! exists('proj') || ! strlen(s:proj) 
	 	let proj=input('Project name:','','custom,projs#complete')
	 endif

	 if ! strlen(proj)
		 call base#subwarn('no project name provided')
		 return 0 
	 endif
	
	 if projs#ex(proj)
		let rw = input('Project already exists, rewrite (y/n)?: ','n')

		if rw != 'y'
			return 0
		endif
	 endif
	
	 let texfiles={}
	 let texfileids=projs#var('secnamesbase')
	 
	 for id in texfileids
	      let texfiles[id]=id
	 endfor
	
	 call map(texfiles, "proj . '.' . v:key . '.tex' ")
	 call extend(texfiles, { '_main_' : proj . '.tex' } )
	
	 let creator = base#catpath('perlscripts','tex_create_proj.pl')

	 if !filereadable(creator)
		call projs#warn('Projs Creator script NOT found!')
		return 0
	 endif
	
	 """ fill in base sections: 
	 """   preamble, packages, begin etc. 
	 for [id,file] in items(texfiles)
		 		let cmd = ' perl ' . creator  
					\ . ' --dir  ' . projs#root() 
					\ . ' --proj ' . proj
					\ . ' --sec  ' . id
					\ . ' --struct  ' . projstruct
					\ . ' --force  '
				if ! base#sys(cmd)
					return 0
				endif
	 endfor
	
	 """ append the name of the project being created to 
	 """   PROJS.i.dat
	 if ! base#sys(' perl ' . creator 
	        \ . ' --proj ' . proj
	        \ . ' --appenddat '
	        \ . ' --force '
	       	\ ) 
			return 0
	 endif
	
	 for file in values(texfiles)
		 if filereadable(file)
	     	if ! base#sys("git add " . file )
					return 0
				endif
		 endif
	 endfor
	
	 let s:proj = proj
	
	 call projs#genperl()
	
	 call base#echoredraw('Created new project: ' . proj)

	 let s:proj = proj
	 call base#var('proj',proj)
	
	 "let menuprojs=input('Load projs menu? (y/n): ', 'n')
	 "if menuprojs == 'y'
			 "MenuReset projs
	 "endif

	 let loadmain=input('Load the main project file? (y/n): ', 'n')
	 if loadmain == 'y'
		VSECBASE _main_
	 endif
 endif
	
 return 1

endf

function! projs#viewproj (...)

call projs#rootcd()

 """ delete buffers from the previously loaded project
 "RFUN DC_Proj_BufsDelete
 "BuffersWipeAll

 let sec=''
 if a:0
    let s:proj = matchstr(a:1,'^\zs\w\+\ze')
    let sec    = matchstr(a:1,'^\w\+\.\zs\w\+\ze')
else
	let s:proj=base#getfromchoosedialog({ 
		 	\ 'list'        : projs#list(),
		 	\ 'startopt'    : '',
		 	\ 'header'      : "Available projects are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose a projects by number: ",
		 	\ })

 endif

" let pm     = 'TeX::Project::Generate::' . s:proj
 "let loadpm = input('Load project module ' . pm . '(y/n)? :','n' )

 "if loadpm == 'y'
	"exe 'tag ' . pm
 "endif

 let f = projs#path([ s:proj . '.secorder.i.dat' ])
 call projs#var('secorderfile',f)

 if ! strlen(sec)
	let sec='_main_'
 endif

 call projs#var('secname',sec)
 call projs#var('proj',s:proj)

 call projs#checksecdir()
 
 call projs#opensec(projs#var('secname'))

 "let menuprojs=input('Load projs menu? (y/n): ', 'n')
 "if menuprojs == 'y'
	"MenuReset projs
 "endif
 "
 "
 if (exists(":MakePrg") == 2)
 	MakePrg projs
 endif

endfun

fun! projs#complete (...)

  let comps=[]

  call base#varupdate('projs')

  let comps=projs#list()

  return join(comps,"\n")
endf

fun! projs#checksecdir()

	call projs#var('secdirexists',0)

	let proj = projs#var('proj')
	let dir  = projs#path([ proj ])

	if isdirectory(dir)
		call projs#var('secdirexists',1)
	endif

endf

function! projs#opensec (...)

 if a:0==1
    let sec=a:1
 else
    let sec='body'

    let listsecs = copy(projs#var('secnamesbase'))
    call extend(listsecs,projs#proj#secnames())

    let listsecs=sort(base#uniq(listsecs))

    let sec=base#getfromchoosedialog({ 
      \ 'list'        : listsecs,
      \ 'startopt'    : 'body',
      \ 'header'      : "Available sections are: ",
      \ 'numcols'     : 1,
      \ 'bottom'      : "Choose section by number: ",
      \ })

  endif

  call projs#var("secname",sec)

  let vfile             = ''
  let vfiles            = []

  if base#var('secdirexists')
	let vfile = projs#path([ s:proj, sec . '.tex' ])
  else
	let vfile = projs#path([ s:proj . '.' . sec . '.tex' ])
  endif

  if sec == '_main_'
		for ext in projs#var('extensions_tex')
			let vfile = projs#path([ s:proj . '.' . ext ])
				if filereadable(vfile)
					call add(vfiles, vfile)
				endif
		endfor

  elseif sec == '_dat_defs_'
    let vfile = projs#path([ 'projs', s:proj . '.defs.i.dat' ])

  elseif sec == '_dat_files_'
    let vfile = projs#path([ 'projs', s:proj . '.files.i.dat' ])

  elseif sec == '_dat_files_ext_'
    let vfile = projs#path([ 'projs', s:proj . '.files_ext.i.dat' ])

  elseif sec == '_dat_'
    let vfile = projs#path([ 'projs', s:proj . '.secs.i.dat' ])

    call projs#gensecdat()

    return
  elseif sec == '_osecs_'
    call projs#opensecorder()

    return

  elseif sec == '_bib_'
    let vfile = projs#path([ s:proj . '.refs.bib' ])

  elseif sec == '_pl_'
    call extend(vfiles,base#splitglob('projs',s:proj . '.*.pl'))
    let vfile=''
  endif

  if strlen(vfile) 
    call add(vfiles,vfile)
  endif

  call projs#var('curfile',vfile)

  let vfiles=base#uniq(vfiles)

  for vfile in vfiles
    call base#fileopen(vfile) 
  endfor

  return 
endf
	

function! projs#gensecdat (...)
 
 let f = projs#path([ s:proj . '.secs.i.dat' ])
 call projs#var('secdatfile',f)

 let datlines=[]

 for line in projs#var('secnames')
   if ! base#inlist(line,base#qw("_main_ _dat_ _osecs_ _bib_ _pl_ "))
      call add(datlines,line)
   endif
 endfor

 call writefile(datlines,projs#var('secdatfile'))

endf

fun! projs#opensecorder()
 
  let f = projs#path([s:proj . '.secorder.i.dat' ])

  call projs#var('secorderfile',f)
  exe 'tabnew ' . projs#var('secorderfile')

  MakePrg projs

endf

 
"" Remove the project 
""  This function does not affect the current value of s:proj 
""			if s:proj is different from the project being removed.
""			On the other hand, if s:proj is the project requested to be removed,
""     s:proj is unlet in the end of the function body

" former DC_PrjRemove


function! projs#initvars (...)
	let s:projvars={}
endf

function! projs#echo(text,...)

	let prefix=''
	if a:0
		let opts=a:1

		if opts['prefix']
			let prefix=opts['prefix']
		endif
	endif

	call base#echo({ 
		\	"text" : a:text, 
		\	"hl"   : "MoreMsg",
		\	"prefix"  : prefix,
		\	})

endfunction

function! projs#info ()

	let g:hl      = 'MoreMsg'
	let indentlev = 2
	let indent    = repeat(' ',indentlev)
	let prefix=''

	call base#echoprefix(prefix)

	let proj     = projs#var('proj')
	let secname  = projs#var('secname')
	let secnames = projs#proj#secnames()
		
	call base#echo({ 'text' : "PROJECTS ", 'hl' : 'Title' } )
	
	call base#echo({ 'text' : "Current project: " } )
	call base#echo({ 
		\ 'text' : "proj => " . proj, 
		\ 'indentlev' : indentlev, })
	
	call base#echo({ 'text' : "Current section: " } )
	call base#echo({ 
		\ 'text' : "secname => " . secname, 
		\ 'indentlev' : indentlev })

	call base#echo({ 'text' : "Sections: " } )
	call base#echo({ 
		\ 'text' : "secnames => " . "\n\t" . join(secnames,"\n\t"), 
		\ 'indentlev' : indentlev })

	call projs#checksecdir()

	let vv=base#qw('texoutdir texmode')
	for v in vv
		call base#echo({ 'text' : v . " => " . projs#var(v) } )
	endfor


endf

function! projs#init (...)

	let prefix="(projs#init) "
	call projs#echo("Initializing projs plugin...",{ "prefix" : prefix })

	let projsdir  = base#envvar('PROJSDIR')

	call base#pathset({
		\	'projs' : projsdir,
		\	})
	
	let datvars=''
	let datvars.=" secnamesbase makesteps "
	let datvars.=" projecttypes projectstructures "

	let e={
		\	"root"           : base#path('projs') ,
		\	"varsfromdat"    : base#qw(datvars)   ,
		\	"extensions_tex" : base#qw('tex')     ,
		\	}

	if exists("s:projvars")
		call extend(s:projvars,e)
	else
		let s:projvars=e
	endif

	if ! exists("s:proj") | let s:proj='' | endif
		
	for v in projs#var('varsfromdat')
		call projs#varsetfromdat(v)
	endfor

	call projs#varsetfromdat('vars','Dictionary')

	let vars =  projs#var('vars')
	for [k,v] in items(vars)
		call projs#var(k,v)
	endfor
	call projs#var('texoutdir',projs#root())

	let varlist=sort(keys(s:projvars))
	call projs#var('varlist',varlist)

endfunction

function! projs#listwrite2dat (...)

 call base#echoprefix("(projs#listwrite2dat) " )

 if a:0
 	let list = a:1
	if base#type(list) != 'List'
		call base#warn({ "text" : "1st input parameter should of type List" })
		return 0
	endif
 else
	let list = projs#list()
 endif

 let dfile = projs#path([ 'PROJS.i.dat' ])
 call writefile(list,dfile)
	
endfunction

" get the value of root dir
" set the value of root dir

function! projs#root (...)
	if a:0
		let root = a:1
		call projs#var('root',root)
	endif
	return projs#var('root')
endf	

function! projs#rootcd ()
	let dir =  projs#var('root')
	exe 'cd ' . dir
endf	

function! projs#plgdir ()
	return projs#var('plgdir')
endf	

function! projs#datadir ()
	return projs#var('datadir')
endf	

function! projs#plgcd ()
	let dir = projs#plgdir()
	exe 'cd ' . dir
endf	

function! projs#listfromdat ()
	let file = ap#file#catfile([ projs#root(), 'PROJS.i.dat' ])
	let list = base#readdatfile({ 
			\ "file" : file, 
			\ "type" : "List", 
			\ "sort" : 1,
			\ "uniq" : 1,
			\ })
	call projs#var("list",list)
	return list
endf	

function! projs#listfromfiles ()
	let root = projs#root()

	let list = base#find({ 
		\ "dirs" : [ root ]                  ,
		\ "ext"  : [ "tex" ]                 ,
		\ "relpath" : 1                      ,
		\ "pat"  : '^\(\w\+\)\.\(\w\+\)\.tex$' ,
	    \ })

	let nlist=[]
	let found={}
	for p in list
		let p = substitute(p,'^\(\w\+\).*','\1','g')

		if !get(found,p,0)
			call add(nlist,p)
			let found[p]=1
		end
	endfor

	return nlist
endf	

function! projs#list ()

	let list=[]
	if ! projs#varexists("list")
		let list = projs#listfromdat()
	else
		let list = projs#var("list")
	end
	return list
endf	

function! projs#listadd (proj)
	let list = projs#list()

	if ! projs#ex(a:proj)
		call add(list,proj)
	endif

	call projs#var("list",list)
	
endfunction

function! projs#ex (proj)

	let list = projs#list()
	if index(list,a:proj) >= 0
		return 1
	endif

	return 0

endfunction

"""projs_path
"
"
"" projs#path(['a', 'b'])
"" projs#path(base#qw('a b'))

function! projs#path (pa)
	let root = projs#root()
	let arr = [ root ]
	call extend(arr,a:pa)

	let fullpath = base#file#catfile(arr)

	return fullpath
	
endfunction

function! projs#var (...)
	if a:0 == 1
		let var = a:1
		return projs#varget(var)
	elseif a:0 == 2
		let var = a:1
		let val = a:2
		return projs#varset(var,val)
	endif
endfunction

function! projs#varecho (varname)
	echo projs#var(a:varname)
endfunction

function! projs#varget (varname)
	
	if exists("s:projvars[a:varname]")
		let val = copy( s:projvars[a:varname] )
	else
		call projs#warn("Undefined variable: " . a:varname)
		let val = ''
	endif

	return val
	
endfunction

function! projs#varset (varname, value)

	let s:projvars[a:varname] = a:value
	
endfunction

function! projs#varexists (varname)
	if exists("s:projvars")
		if exists("s:projvars[a:varname]")
			return 1
		else
			return 0
		endif
	else
		return 0
	endif
	
endfunction

function! projs#varsetfromdat (varname,...)
	let datafile = projs#datafile(a:varname)

	if a:0
		let type = a:1
	else
		let type = "List"
	endif

	if !filereadable(datafile)
		call projs#warn('NO datafile for: ' . a:varname)
		return 0
	endif

	let data = base#readdatfile({ 
		\   "file" : datafile ,
		\   "type" : type ,
		\	})

	call projs#var(a:varname,data)

	return 1

endfunction


function! projs#datafile (id)
	let files = projs#datafiles(a:id)
	let file = get(files,0,'')
	return file
endfunction

function! projs#datafiles (id)
	let datadir = projs#datadir()
	let file = a:id . ".i.dat"

	let files = base#find({
		\ "dirs"    : [ datadir ],
		\ "subdirs" : 1,
		\ "pat"     : '^'.file.'$',
		\	})

	return files
endfunction

function! projs#warn (text)
	let prefix = "--PROJS--"
	call base#warn({ "text" : a:text, "prefix" : prefix })
	
endfunction

 
function! projs#renameproject(old,new)

 call base#CD('projs')

 call system("rename 's/^" . a:old . '\.*/' . a:new . "./g' " . a:old . ".*")
 
endfunction

 
""used in:
""  projs#new

function! projs#genperl(...)

 let pmfiles={}

 call extend(pmfiles, {
			\	'generate_pm' : g:paths['perlmod'] . '/lib/TeX/Project/Generate/' . s:proj . '.pm',  
			\	'generate_pl' : g:paths['projs']  . '/generate.' . s:proj . '.pl',  
 			\	})
 
endfunction

