
" projs#secfile (sec)
"
function! projs#secfile (...)
	
	let sec = a:1

	let dot = '.'

	let proj = projs#proj#name()
	let secfile = ''

	if sec == '_main_'
		let secfile = projs#path([proj.'.tex'])
	elseif sec == '_vim_'
		let secfile = projs#path([proj.'.vim'])
	elseif sec == '_osecs_'
		let secfile = projs#path([proj.'.secorder.i.dat'])
	elseif sec == '_bib_'
		let secfile = projs#path([proj.'.refs.bib'])
	else
		let secfile = projs#path([proj.dot.sec.'.tex'])
	endif

	return secfile
	
endfunction

"call projs#secfromfile ({ "file" : file, "type" : "basename", "proj" : proj })

function! projs#secfromfile (...)
	let ref = {}
	if a:0 | let ref = a:1 | endif

	let proj = projs#proj#name()

	let file = get(ref,'file','')
	let type = get(ref,'type','basename')
	let proj = get(ref,'proj',proj)

	if type == 'basename'
		let basename = file 
	
		if basename =~ '\.\(\w\+\)\.tex$'
			let sec = substitute(basename,'^.*\.\(\w\+\)\.tex$','\1','g')
		elseif basename == proj . '.tex' 
			let sec = '_main_'
		elseif basename =~ '\.\(\w\+\)\.vim$'
			let sec = '_vim_'
		endif
		return sec
	endif

endfunction

" projs#newfile(id)

function! projs#newsecfile(sec)

	let sec  = a:sec
	let proj = projs#proj#name()

	call projs#echo("Creating file:\n\t" . sec )
	let lines = []
	let file = projs#path([ proj . '.' . sec . '.tex'])

	let secs = base#qw("preamble body")

"""newsec__main__
	if sec == '_main_'

		let file = projs#path([ proj.'.tex'])

		call add(lines,' ')
		call add(lines,'%%file f_main')
		call add(lines,' ')
		call add(lines,'\def\PROJ{'.proj.'}')
		call add(lines,' ')
		"call add(lines,'\def\ii#1{\include{'.proj.'.#1.tex}}')
		"
		call add(lines,'% --------------')
		call add(lines,'\def\ii#1{\InputIfFileExists{\PROJ.#1.tex}{}{}}')
		call add(lines,'\def\iif#1{\input{\PROJ/#1.tex}}')
		call add(lines,'% --------------')
		call add(lines,' ')

		call add(lines,'\ii{preamble}')

		call add(lines,'\begin{document}')
		call add(lines,' ')
		call add(lines,'\ii{body}')
		call add(lines,' ')
		call add(lines,'\end{document}')
		call add(lines,' ')

"""newsec_body
	elseif sec == 'body'

		call add(lines,' ')
		call add(lines,'%%file f_' . sec)
		call add(lines,' ')

"""newsec_preamble
	elseif sec == 'preamble'

		let packs = projs#var('tex_packs_preamble')

		let packopts = {
			\ 'fontenc'  : 'OT1,T2A,T3',
			\ 'inputenc' : 'utf8',
			\ }

		call add(lines,' ')
		call add(lines,'%%file f_'. sec)
		call add(lines,' ')
		call add(lines,'\documentclass[a4paper,11pt]{extreport}')
		call add(lines,' ')
		call add(lines,'\usepackage{mathtext}')
		call add(lines,'\usepackage{extsizes}')
		call add(lines,'\usepackage[OT1,T2A,T3]{fontenc}')
		call add(lines,'\usepackage[english,ukrainian]{babel}')
		call add(lines,' ')
 
	endif

	call writefile(lines,file)
	
endfunction

"
"
"""projs_new

"" projs#new()
"" projs#new(proj)
"" projs#new(proj,{ use_creator : 0 })
"

function! projs#new (...)
 call base#echoprefix('(projs#new)')

 let delim=repeat('-',50)
 let proj = ''

 echo delim
 echo " "
 echo "This will create a new TeX project skeleton "
 echo "    in projects' root directory: " . projs#root() 
 echo " "
 echo delim

 let yn=input('Continue? (y/n): ','y')
 if yn != 'y'
   return 0
 endif

 let newopts={ 
 	\	'use_creator' : 0 ,
 	\	'git_add'     : 0 ,
 	\	}
  
 if a:0
 	 let proj     = a:1
	 let projtype = 'regular'

	 if (a:0 == 2 && ( base#type(a:2) == 'Dictionary'))
		call extend(newopts,a:2)
	 endif

 endif

 echo " "
 echo "Provided options for new project creation:"
 echo " "
 echo newopts
 echo " "
 echo delim

 let projtype = base#getfromchoosedialog({ 
		 	\ 'list'        : projs#var('projecttypes'),
		 	\ 'startopt'    : 'regular',
		 	\ 'header'      : "Available project types are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose a project type by number: ",
		 	\ })

 let projstruct = base#getfromchoosedialog({ 
		 	\ 'list'        : projs#var('projectstructures'),
		 	\ 'startopt'    : 'in_root',
		 	\ 'header'      : "Available project structures are: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose a project structure by number: ",
		 	\ })

 call projs#rootcd()

"""projtype_regular
 if projtype == 'regular'

	 if ! ( exists('proj') && strlen(proj) )
	 	let proj=input('Project name:','','custom,projs#complete')
	 endif

	 if ! strlen(proj)
		 call base#warn({ 'text' : 'no project name provided' })
		 return 0 
	 endif
	
	 if projs#ex(proj)
		let rw = input('Project already exists, rewrite (y/n)?: ','n')

		if rw != 'y'
			return 0
		endif
	 endif

	 call projs#proj#name(proj)
	
	 let texfiles={}
	 let secnamesbase = projs#var('secnamesbase')
	 
	 for id in secnamesbase
	    let texfiles[id]=id
	 endfor
	
	 call map(texfiles, "proj . '.' . v:key . '.tex' ")
	 call extend(texfiles, { '_main_' : proj . '.tex' } )
	
	 let creator = base#catpath('perlscripts','tex_create_proj.pl')

	 let uc = get(newopts,'use_creator',0)

	 let use_vim = ! (uc && filereadable(creator))

	 if use_vim
		for sec in base#qw(" _main_ preamble body ")
			call projs#newsecfile(sec)
		endfor

	 elseif (uc && filereadable(creator)) 
	
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
	 endif

	 if get(newopts,'git_add',0)
		 for file in values(texfiles)
			 if filereadable(file)
		     	if ! base#sys("git add " . file )
					return 0
				endif
			 endif
		 endfor
	 endif

	 let s:proj = proj
	
	 call projs#genperl()
	
	 call base#echoredraw('Created new project: ' . proj)

	 let s:proj = proj
	 call base#var('proj',proj)

	 call projs#listadd(proj)
	
	 "let menuprojs=input('Load projs menu? (y/n): ', 'n')
	 "if menuprojs == 'y'
			 "MenuReset projs
	 "endif

	 let loadmain=input('Load the main project file? (y/n): ', 'n')
	 if loadmain == 'y'
		VSECBASE _main_
	 endif

	 TgUpdate projs_this
 endif

 call base#echoprefixold()
	
 return 1

endf

"" projs#selectproject ()
"" projs#selectproject (pat)

function! projs#selectproject (...)
	let pat  = a:1
	let list = projs#list()

	let s:proj=base#getfromchoosedialog({ 
	 	\ 'list'        : ,
	 	\ 'startopt'    : '',
	 	\ 'header'      : "Available projects are: ",
	 	\ 'numcols'     : 1,
	 	\ 'bottom'      : "Choose a project by number: ",
	 	\ })
	return s:proj
	
endfunction



function! projs#viewproj (...)

	call projs#rootcd()

	 """ delete buffers from the previously loaded project
	 "RFUN DC_Proj_BufsDelete
	 "BuffersWipeAll

	let sec = ''
	if a:0
		let s:proj = matchstr(a:1,'^\zs\w\+\ze')
		let sec    = matchstr(a:1,'^\w\+\.\zs\w\+\ze')
	else
		let s:proj=projs#selectproject()
 endif

 call projs#proj#name(s:proj)

" let pm     = 'TeX::Project::Generate::' . s:proj
 "let loadpm = input('Load project module ' . pm . '(y/n)? :','n' )

 "if loadpm == 'y'
	"exe 'tag ' . pm
 "endif

	let f = projs#secfile('_osecs_')
	call projs#var('secorderfile',f)

	if ! strlen(sec)
		let sec='_main_'
	endif

	call projs#var('secname',sec)
	call projs#var('proj',s:proj)

	let secnames = projs#proj#secnames()
	call projs#var('secnames')
	
	call projs#checksecdir()
	
	call projs#opensec(projs#var('secname'))

 "let menuprojs=input('Load projs menu? (y/n): ', 'n')
 "if menuprojs == 'y'
	"MenuReset projs
 "endif
 "
	if (exists("*make#makeprg"))
		call make#makeprg('projs',{ 'echo' : 0 })
	endif

	let vimf = projs#path([ s:proj . '.vim' ])
	if filereadable(vimf)
		exe 'source ' . vimf
	endif

	TgSet projs_this

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

  if projs#var('secdirexists')
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

  elseif sec == '_vim_'
    let vfile = projs#path([ s:proj . '.vim' ])

  elseif sec == '_pl_'
    call extend(vfiles,base#splitglob('projs',s:proj . '.*.pl'))
    let vfile=''
  endif

  if strlen(vfile) 
    call add(vfiles,vfile)
  endif

  call projs#var('curfile',vfile)

  let vfiles = base#uniq(vfiles)

  for vfile in vfiles
    call base#fileopen(vfile) 
  endfor

  call base#stl#set('projs')
  KEYMAP russian-jcukenwin

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

	call base#echo({ 'text' : "Projects directory: " } )
	call base#echo({ 
		\ 'text' : "projs#root() => " . projs#root(),
		\ 'indentlev' : indentlev, })

	call base#echo({ 
		\ 'text' : "$PROJSDIR => " . base#envvar('PROJSDIR'), 
		\ 'indentlev' : indentlev, })
	
	call base#echo({ 'text' : "Current project: " } )
	call base#echo({ 
		\ 'text' : "proj => " . proj, 
		\ 'indentlev' : indentlev, })
	
	call base#echo({ 'text' : "Current section: " } )
	call base#echo({ 
		\ 'text' : "secname => " . secname, 
		\ 'indentlev' : indentlev })

	let cnt = input('Show list of sections? (1/0): ',1)
	if cnt
		call base#echo({ 'text' : "Sections: " } )
		call base#echo({ 
			\ 'text' : "secnames => " . "\n\t" . join(secnames,"\n\t"), 
			\ 'indentlev' : indentlev })
	endif

	call projs#checksecdir()

	let vvs = 'texoutdir texmode makesteps secnamesbase'
	let vv  = base#qw(vvs)

	let cnt = input('Show Values for variables '.vvs.' ? (1/0): ',1)

	if cnt
		for v in vv
			if exists("vl") | unlet vl | endif
			let vl = projs#var(v)
	
			if base#type(vl) == 'List'
				let str = "\n\t" . join(vl,"\n\t")
		    else
				let str = vl
			endif
			call base#echo({ 'text' : v . " => " . str  } )
		endfor
	endif


endf

" call projs#filejoinlines ()
" call projs#filejoinlines ({ "sec" : sec })

function! projs#filejoinlines (...)
	let ref = {}
	if a:0 | let ref = a:1 | endif

	let sec = get(ref,'sec','_main_')

	let proj = projs#proj#name()
	call projs#rootcd()

	let sf={}
	let sf[sec] = projs#secfile(sec)
	let f=sf[sec]

	let flines = readfile(f)
	let lines = []

	let pat='^\s*\\ii{\(\w\+\)}.*$'

	let delim=repeat('%',50)

	for line in flines
		if line =~ pat
			let iisec = substitute(line,pat,'\1','g')

			let iilines=projs#filejoinlines({ "sec" : iisec })

			call add(lines,delim)
			call add(lines,'%% ' . line)
			call add(lines,delim)

			call extend(lines,iilines)
		else
			call add(lines,line)
		endif
	endfor

	if sec == '_main_'
		let jdir = projs#path(['joins'])
		call base#mkdir(jdir)

		let jfile = base#file#catfile([ jdir, proj . '.tex' ])
	
		echo 'Writing joined lines into: ' 
		echo '  ' . jfile
	
		call writefile(lines,jfile)

	endif

	return lines


endf

function! projs#maps ()

	nmap <silent> ;;co :copen<CR>
	nmap <silent> <F1> :copen<CR>
	nmap <silent> <F2> :cn<CR> 
	nmap <silent> <F3> :cp<CR>
	nmap <silent> <F4> :PrjMake<CR>
	nmap <silent> <F5> :cclose<CR>
	
endfunction

function! projs#builddir (...)
	let proj     = projs#proj#name()
	let broot    = projs#var('rootbuilddir')
	let builddir = base#file#catfile([ broot, proj ])

	return builddir

endfunction

"""projs_init

"call projs#init ()       -  ProjsInit     - use environment variable PROJSDIR
"call projs#init (dirid)  -  ProjsInit DIRID - specify custom projects' directory, full path is base#path(DIRID)
"
"call projs#init (dirid,'projs_new')

function! projs#init (...)

	let projsdir  = base#envvar('PROJSDIR')
	let projsid   = 'projs'
	if a:0 
		let dirid = a:1 
		let dir = base#path(dirid)

		call base#mkdir(dir)

		if isdirectory(dir)
			let projsdir = dir
			if a:0 == 2
				let projsid = a:2
			endif
		endif
	endif

    let g:texlive={
		\  'TEXMFDIST'  : projs#tex#kpsewhich('--var-value=TEXMFDIST'),
		\  'TEXMFLOCAL' : projs#tex#kpsewhich('--var-value=TEXMFLOCAL'),
		\  }
	let g:pdfviewer = 'evince'

	let prefix="(projs#init) "
	call projs#echo("Initializing projs plugin, \n\t projsdir => " . projsdir ,{ "prefix" : prefix })

	call base#pathset({
		\	projsid : projsdir,
		\	})

	
	let datvars=''
	let datvars.=" secnamesbase makesteps "
	let datvars.=" projecttypes projectstructures "
	let datvars.=" projsdirs "
	let datvars.=" prjmake_opts "

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

 	let pdfout = projs#path([ 'pdf_built' ])
	call projs#var('pdfout',pdfout)
 	call base#mkdir(pdfout)

	"let texoutdir = projs#path([ 'builds' ])
	"call projs#var('texoutdir',texoutdir)

	let rootbuilddir = projs#path([ 'builds' ])
	call projs#var('rootbuilddir',rootbuilddir)
	call base#mkdir(rootbuilddir)

	if ! exists("s:proj") | let s:proj='' | endif
		
	for v in projs#var('varsfromdat')
		call projs#varsetfromdat(v)
	endfor

	let projsdirs=projs#var('projsdirs')
	call projs#var('projsdirslist',projsdirs)

	call projs#varsetfromdat('vars','Dictionary')

	let vars =  projs#var('vars')
	for [k,v] in items(vars)
		call projs#var(k,v)
	endfor


	let varlist=sort(keys(s:projvars))
	call projs#var('varlist',varlist)

	let list = projs#listfromfiles()
	call projs#var('list',list)

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
	let dir =  projs#root()
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
		"let list = projs#listfromdat()
		let list = projs#listfromfiles()
	else
		let list = projs#var("list")
	end
	return copy(list)
endf	

function! projs#listadd (proj)
	let list = projs#list()

	if ! projs#ex(a:proj)
		call add(list,a:proj)
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

function! projs#prjmake (...)
	let opt = 'latex'
	if a:0
		let opt = a:1
	endif
	let proj = projs#proj#name()
	call projs#proj#make({ "proj" : proj, "opt" : opt })
endfunction

function! projs#buildnum (...)
 if a:0
	let proj = a:1
 else
	let proj = projs#proj#name()
 endif
		
 """" --------------------- get build number, initialize output pdf directory
 let pdfout = projs#path([ 'pdf_built' ])
 call base#mkdir(pdfout)

 let bnum = 1
 let pdfs = base#find({ 
 	\ "dirs" : [ pdfout ], 
	\ "exts" : ["pdf"],
	\ "relpath" : 1,
	\ })

 let bnums = []
 let pat = '^'.proj.'\(\d\+\)\.pdf'
 for pdf in pdfs
	if pdf =~ pat
		let bnum = substitute(pdf,pat,'\1','g')
		call add(bnums,str2nr(bnum))
	else
		continue
	endif
 endfor

 func! Cmp(i1, i2)
   return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
 endfunc

 let bnums = sort(bnums,"Cmp")

 if len(bnums)
 	let bnum = bnums[-1] + 1
 else
	let bnum = 1
 endif
 let snum = bnum . ''

 """" ---------------------
 return snum
	
endfunction

function! projs#setbuildvars (...)
 let ref = {}
 if a:0 | let ref = a:1 | endif
		
 let proj = projs#proj#name()

 let bnum      = projs#buildnum()
 let texoutdir = base#file#catfile([ projs#builddir(), bnum ])

 call base#mkdir(texoutdir)
 call projs#var('texoutdir',texoutdir)

 let texmode    = projs#var('texmode')
 let texjobname = proj

 let pdfout = projs#var('pdfout')

 call projs#var('texjobname',texjobname)
 call projs#var('buildnum',bnum)

 if get(ref,'echo',1)
	 echo '---------- projs#setbuildvars(...)--------'
	 echo 'Setting latex build-related options:'
	 echo '  buildnum         => '  . bnum
	 echo '  texjobname       => '  . texjobname
	 echo '  texmode          => '  . texmode
	 echo '---------- end projs#setbuildvars---------'
 endif
	
endfunction

