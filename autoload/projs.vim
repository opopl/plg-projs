
function! projs#secfilecheck (...)
    let sec = a:1
    let sfile = projs#secfile(sec)

    if !filereadable(sfile)
        call projs#newsecfile(sec)
    endif

    return 1
endf

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

  elseif sec == '_dat_defs_'
    let secfile = projs#path([ proj . '.defs.i.dat' ])

    elseif sec == '_dat_citn_'
        let secfile = projs#path([proj.'.citn.i.dat'])

    elseif sec == '_bib_'
        let secfile = projs#path([proj.'.refs.bib'])

    elseif sec == '_join_'
        let secfile = projs#path(['joins',proj.'.tex'])

    elseif sec == '_build_pdflatex_'
        if has('win32')
            let secfile = projs#path([ 'b_' . proj . '_pdflatex.bat' ])
        endif
    elseif sec == '_build_htlatex_'
        if has('win32')
            let secfile = projs#path([ 'b_' . proj . '_htlatex.bat' ])
        endif
    elseif sec == '_main_htlatex_'
            let secfile = projs#path([ proj . '.main_htlatex.tex' ])
    else
        let secfile = projs#path([proj.dot.sec.'.tex'])
    endif

    return secfile
    
endfunction

function! projs#namefromfile (...)
	let ref = {}
	if a:0 | let ref = a:1 | endif

	let file = get(ref,'file','')
	let bname = fnamemodify(file,':p:t')
	let name = substitute(bname,'^\(\w\+\)\..*$','\1','g')

	return name

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
    
        if basename =~ '^\w\+\.\(.*\)\.tex$'
            let sec = substitute(basename,'^\w\+\.\(.*\)\.tex$','\1','g')
        elseif basename == proj . '.tex' 
            let sec = '_main_'
        elseif basename =~ '\.\(\w\+\)\.vim$'
            let sec = '_vim_'
        elseif basename =~ '\.\(\w\+\)\.bib$'
            let sec = '_bib_'
        endif
        return sec
    endif

endfunction

" projs#newsecfile(sec)
" projs#newsecfile(sec,{ "git_add" : 1 })
" projs#newsecfile(sec,{ "view" : 1 })

function! projs#newsecfile(sec,...)

    let sec  = a:sec
    let proj = projs#proj#name()

    let ref = { 
        \   "git_add" : 0, 
        \   "view"    : 0, 
        \   }

    if a:0 
        let refadd = a:1 
        call extend(ref,refadd)
    endif

    call projs#echo("Creating file:\n\t" . sec )
    let lines = []

    let file = projs#secfile(sec)

    let secs = base#qw("preamble body")

"""newsec__main__
    if sec == '_main_'

        let file = projs#path([ proj.'.tex'])

        call add(lines,' ')
        call add(lines,'%%file f_main')
        call add(lines,' ')
        call add(lines,'\def\PROJ{'.proj.'}')
        call add(lines,' ')

        call add(lines,'% --------------')
        call add(lines,'\def\ii#1{\InputIfFileExists{\PROJ.#1.tex}{}{}}')
        call add(lines,'\def\iif#1{\input{\PROJ/#1.tex}}')
        call add(lines,'\def\idef#1{\InputIfFileExists{_def.#1.tex}{}{}}')
        call add(lines,'% --------------')

        let ProjRootSec = input('(_main_) ProjRootSec:','part','custom,projs#complete#projrootsec')

        call add(lines,'% --------------')
        call add(lines,'\def\ProjRootSec{'.ProjRootSec.'}')
        call add(lines,'% --------------')

        call add(lines,' ')

        call add(lines,'\ii{preamble}')
        call add(lines,' ')
        call add(lines,'%Definitions ')
        call add(lines,'\ii{defs}')
        call add(lines,' ')

        call add(lines,'\begin{document}')
        call add(lines,' ')
        call add(lines,'\ii{body}')
        call add(lines,' ')
        call add(lines,'%Bibliography ')
        call add(lines,'\ii{bib}')
        call add(lines,' ')
        call add(lines,'%Index ')
        call add(lines,'\ii{index}')
        call add(lines,' ')
        call add(lines,'\end{document}')
        call add(lines,' ')

"""newsec_bib
    elseif sec == 'bib'

        let bibstyle = input('Bibliography style:','unsrt')
        let bibfile = input('Bibliography:','\PROJ.refs')

        call add(lines,'\phantomsection')
        "call add(lines,'\renewcommand\bibname{<++>}')

        call add(lines,'\addcontentsline{toc}{chapter}{\bibname}')

        call add(lines,'\bibliographystyle{'.bibstyle.'}')
        call add(lines,'\bibliography{'.bibfile.'}')
"""newsec_title
    elseif sec == 'index'
        call add(lines,'\begin{titlepage}')
		call add(lines,'\end{titlepage}')

"""newsec_index
    elseif sec == 'index'

        call add(lines,'\phantomsection')
        "call add(lines,'\printindex')

"""newsec_body
    elseif sec == 'body'

        call add(lines,' ')
        call add(lines,'%%file f_' . sec)
        call add(lines,' ')

"""newsec_cfg
    elseif sec == 'cfg'

        call add(lines,' ')
        call add(lines,'%%file f_' . sec)
        call add(lines,' ')

        let ln  = projs#qw#rf('data tex tex4ht_cfg.tex')
        call extend(lines,ln)

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

        let ln  = projs#qw#rf('data tex preamble.tex')
        call extend(lines,ln)

    elseif sec == '_dat_'
    elseif sec == '_dat_defs_'
    elseif sec == '_vim_'
    elseif sec == '_bib_'

        call add(lines,' ')
        call add(lines,'"""file f__vim_ ')
        call add(lines,' ')
        call add(lines,' ')

"""newsec__build_htlatex
    elseif sec == '_build_htlatex_'

        let outd = [ 'builds', proj, 'b_htlatex' ]

        let pcwin = [ '%Bin%' ]
        let pcunix = [ '.' ]

        call extend(pcwin,outd)
        call extend(pcunix,outd)

        let outdir_win = base#file#catfile(pcwin)

        let outdir_unix = base#file#catfile(pcunix)
        let outdir_unix = base#file#win2unix(outdir_unix)

        let latexopts  = ' -file-line-error '
        let latexopts .= ' -output-directory='. outdir_unix

        call add(lines,' ')
        call add(lines,'set Bin=%~dp0')
        call add(lines,' ')
        "call add(lines,'if not exist %htmout% set htmout=%Bin%\html' )
        call add(lines,'set htmloutdir=%htmlout%\'.proj)
        call add(lines,' ')

        call add(lines,'if exist %htmloutdir% rmdir /q/s  %htmloutdir% ')
        call add(lines,'md %htmloutdir%')
        call add(lines,' ')
        call add(lines,'set outdir='.outdir_win)
        call add(lines,' ')

        call add(lines,'if  exist %outdir% rmdir /q/s  %outdir% ')
        call add(lines,'md %outdir%')
        call add(lines,' ')
        call add(lines,'cd %Bin%')
        call add(lines,' ')
        call add(lines,'copy '.proj.'.*.tex %outdir%' )
        call add(lines,'copy '.proj.'.tex %outdir%' )
        call add(lines,'copy *.sty %outdir%' )
        call add(lines,'copy _def.*.tex %outdir%' )
        call add(lines,'copy inc.*.tex %outdir%' )
        call add(lines,' ')
        call add(lines,'cd %outdir%')
        call add(lines,' ')
        call add(lines,'copy '.proj.'.cfg.tex main.cfg' )
        call add(lines,'copy '.proj.'.main_htlatex.tex main.tex' )
        call add(lines,' ')
        call add(lines,'htlatex main main')
        call add(lines,' ')
        call add(lines,'copy *.html %htmloutdir%\ ')
        call add(lines,'copy *.png %htmloutdir%\ ')
        call add(lines,' ')
        call add(lines,'cd %Bin% ')
        call add(lines,' ')

        call projs#newsecfile('_main_htlatex_')

        let secc = base#qw('_main_htlatex_ cfg')
        for sec in secc
            call projs#secfilecheck(sec)
        endfor

    elseif sec == '_main_htlatex_'

        call add(lines,' ')
        call add(lines,'%%file f_'. sec)
        call add(lines,' ')
        call add(lines,'\nonstopmode')
        call add(lines,' ')

        let mf = projs#secfile('_main_')
        let ml = readfile(mf)

        call filter(ml,'v:val !~ "^%%file f_main"')

        call extend(lines,ml)

"""newsec__build_pdflatex
    elseif sec == '_build_pdflatex_'

        let outd = [ 'builds', proj, 'b' ]

        let pcwin = [ '%Bin%' ]
        let pcunix = [ '.' ]

        call extend(pcwin,outd)
        call extend(pcunix,outd)

        let outdir_win = base#file#catfile(pcwin)

        let outdir_unix = base#file#catfile(pcunix)
        let outdir_unix = base#file#win2unix(outdir_unix)

        let latexopts  = ' -file-line-error '
        let latexopts .= ' -output-directory='. outdir_unix

        let lns = {
            \ 'pdflatex'  : 'pdflatex '.latexopts.' '.proj ,
            \ 'bibtex'    : 'bibtex '    . proj            ,
            \ 'makeindex' : 'makeindex ' . proj            ,
            \ }
        let bibfile=projs#secfile('_bib_')

        call add(lines,' ')
        call add(lines,'set Bin=%~dp0')
        call add(lines,' ')
        call add(lines,'set outdir='.outdir_win)
        call add(lines,'md %outdir%')
        call add(lines,' ')
        call add(lines,'set bibfile='.bibfile)
        call add(lines,'copy %bibfile% %outdir%')
        call add(lines,' ')
        call add(lines,lns.pdflatex  )
        call add(lines,'rem --- bibtex makeindex --- ')
        call add(lines,'cd %outdir% ')
        call add(lines,lns.bibtex  )
        call add(lines,lns.makeindex  )
        call add(lines,'rem ------------------------ ')
        call add(lines,' ')
        call add(lines,'cd %Bin% ')
        call add(lines,lns.pdflatex  )
        call add(lines,lns.pdflatex  )
        call add(lines,' ')

        let origin = base#file#catfile([ outdir_win, proj.'.pdf'])

        let dests = []

        call add(dests,'%Bin%\pdf_built\b_'.proj.'.pdf' )
        call add(dests,'%PDFOUT%\b_'.proj.'.pdf' )

        for dest in dests
            call add(lines,'copy '.origin.' '.dest)
            call add(lines,' ')
        endfor
    else

        call add(lines,' ')
        call add(lines,'%%file f_' . sec)
        call add(lines,' ')

        let cnt = input('Continue adding? (1/0):',1)

        if cnt
            let addsec = input('Add sectioning? (1/0):',1)
            if addsec
                let seccmd = input('Sectioning command: ','section','custom,tex#complete#seccmds')

                let title = input('Title: ',sec)
                let label = input('Label: ','sec:'.title)

                call add(lines,'\' . seccmd . '{'.title.'}')
                call add(lines,'\label{'.label.'}')
                call add(lines,' ')
            endif
        endif
 
    endif

    call writefile(lines,file)

    if get(ref,'git_add')
        call base#sys("git add " . file)
    endif

    if get(ref,'view')
        exe 'split ' . file
    endif
    
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
    \   'use_creator' : 0 ,
    \   'git_add'     : 0 ,
    \   }
  
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

     let git_add = get(newopts,'git_add',0)
     let git_add = input('Add each new file to git? (1/0)',git_add)

     if use_vim
        let nsecs = " _main_ preamble body cfg bib index"
        let nsecs = input('Sections to be created:',nsecs)

        for sec in base#qw(nsecs)
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

     if git_add
         for file in values(texfiles)
             if filereadable(file)
                if ! base#sys("git add " . file )
                    return 0
                endif
             endif
         endfor
     endif

     let proj = proj
    
     call projs#genperl()
    
     call base#echoredraw('Created new project: ' . proj)

     let proj = proj
     call base#var('proj',proj)

     call projs#listadd(proj)
    
     "let menuprojs=input('Load projs menu? (y/n): ', 'n')
     "if menuprojs == 'y'
             "MenuReset projs
     "endif

     let loadmain=input('Load the main project file? (y/n): ', 'y')
     if loadmain == 'y'
        VSECBASE _main_
     endif

     TgUpdate projs_this
     call projs#update('list')
 endif

 call base#echoprefixold()
    
 return 1

endf

"" projs#selectproject ()
"" projs#selectproject (pat)

function! projs#selectproject (...)
    
    if a:0
        let pat  = a:1
    endif

    let list = projs#list()

    let proj=base#getfromchoosedialog({ 
        \ 'list'        : list,
        \ 'startopt'    : '',
        \ 'header'      : "Available projects are: ",
        \ 'numcols'     : 1,
        \ 'bottom'      : "Choose a project by number: ",
        \ })
    return proj
    
endfunction



function! projs#viewproj (...)

    call projs#rootcd()

     """ delete buffers from the previously loaded project
     "RFUN DC_Proj_BufsDelete
     "BuffersWipeAll

    let sec = ''
    if a:0
        let proj = matchstr(a:1,'^\zs\w\+\ze')
        let sec    = matchstr(a:1,'^\w\+\.\zs\w\+\ze')
    else
        let proj=projs#selectproject()
    endif
    let proj = proj

    if !projs#exists(proj)
        let o = input('Project '.proj.' does not exist, create new? (1/0):',1)
        if o
            call projs#new(proj)
            return 1
        endif
    endif

 call projs#proj#name(proj)

" let pm     = 'TeX::Project::Generate::' . proj
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
    call projs#var('proj',proj)

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
        call make#makeprg('projs_latexmk',{ 'echo' : 0 })
    endif

    let vimf = projs#path([ proj . '.vim' ])
    if filereadable(vimf)
        exe 'source ' . vimf
    endif

    TgSet projs_this

	let loaded=projs#varget('loadedprojs',[])

	call add(loaded,proj)
	call projs#var('loadedprojs',loaded)

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

function! projs#switch (...)

	let proj = ''
	if a:0
		let proj = a:1
	else
		let proj = input('Switch to:','','custom,projs#complete#switch')
	endif

	"let ul = input('Update list? (1/0):',0)
	"if ul | call projs#update('list') | endif

	while ! projs#exists(proj)
		let proj = input('Switch to:','','custom,projs#complete#switch')
		if proj == ''
			let text = 'Project switching aborted'
			redraw!
			call base#echo({ "text": text, "hl" : 'MoreMsg'})
			return
		endif
	endw

	call projs#proj#name(proj)
	call projs#update('secnames')

	let sec = 'body'
	let sec = input('Section to open:',sec,'custom,projs#complete#secnames')

	call projs#opensec(sec)
	
endfunction

function! projs#opensec (...)
 let proj = projs#proj#name()

 if a:0==1
    let sec=a:1

 else
    let sec='body'

    let listsecs = copy(projs#var('secnamesbase'))
    call extend(listsecs,projs#proj#secnames())

    let listsecs=sort(base#uniq(listsecs))

    let sec = base#getfromchoosedialog({ 
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
    let vfile = projs#path([ proj, sec . '.tex' ])
  else
    let vfile = projs#path([ proj . '.' . sec . '.tex' ])
  endif

  let vfile = projs#secfile(sec)

  if sec == '_main_'
        for ext in projs#var('extensions_tex')
            let vfile = projs#path([ proj . '.' . ext ])
                if filereadable(vfile)
                    call add(vfiles, vfile)
                endif
        endfor


  elseif sec == '_dat_citn_'
    let vfile = projs#path([ proj . '.citn.i.dat' ])

  elseif sec == '_dat_files_'
    let vfile = projs#path([ proj . '.files.i.dat' ])

  elseif sec == '_dat_files_ext_'
    let vfile = projs#path([ proj . '.files_ext.i.dat' ])

  elseif sec =~ '^_build_'
    let vfile = projs#secfile(sec)

  elseif sec == '_dat_'
    let vfile = projs#path([ proj . '.secs.i.dat' ])

    call projs#gensecdat()

    return
  elseif sec == '_osecs_'
    call projs#opensecorder()

    return

  elseif sec == '_bib_'
    let vfile = projs#path([ proj . '.refs.bib' ])

  elseif sec == '_join_'
    let vfile = projs#path(['joins',proj.'.tex'])

    if !filereadable(vfile)
        call projs#filejoinlines()
    endif

  elseif sec == '_vim_'
    let vfile = projs#path([ proj . '.vim' ])

  elseif sec == '_pl_'
    call extend(vfiles,base#splitglob('projs',proj . '.*.pl'))
    let vfile=''
  endif

  if strlen(vfile) 
    call add(vfiles,vfile)
  endif

  call projs#var('curfile',vfile)

  let vfiles = base#uniq(vfiles)

  for vfile in vfiles
    if !filereadable(vfile)
        call projs#newsecfile(sec)
    endif
    call base#fileopen(vfile) 
  endfor

  call base#stl#set('projs')
  KEYMAP russian-jcukenwin

  return 
endf
    

function! projs#gensecdat (...)
 
 let f = projs#path([ proj . '.secs.i.dat' ])
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
 
  let f = projs#path([proj . '.secorder.i.dat' ])

  call projs#var('secorderfile',f)
  exe 'tabnew ' . projs#var('secorderfile')

  MakePrg projs

endf

 
"" Remove the project 
""  This function does not affect the current value of proj 
""          if proj is different from the project being removed.
""          On the other hand, if proj is the project requested to be removed,
""     proj is unlet in the end of the function body

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
        \   "text" : a:text, 
        \   "hl"   : "MoreMsg",
        \   "prefix"  : prefix,
        \   })

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

	call projs#update('loaded')
        
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

    call base#echo({ 'text' : "Loaded projects: " } )
	let	loaded=projs#var('loaded')
    call base#echo({ 
        \ 'text' : "loaded => " . base#dump(loaded), 
        \ 'indentlev' : indentlev })

    let cnt = input('Continue? (1/0): ',0)
	if !cnt | return | endif

    let cnt = input('Show list of sections? (1/0): ',1)
    if cnt
        call base#echo({ 'text' : "Sections: " } )
        call base#echo({ 
            \ 'text' : "secnames => " . "\n\t" . join(secnames,"\n\t"), 
            \ 'indentlev' : indentlev })
    endif

    call projs#checksecdir()

    let vvs = 'texoutdir texmode prjmake_opt secnamesbase pdfout'
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

	return

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

    let pats={
        \ 'ii'    : '^\s*\\ii{\(\w\+\)}.*$',
        \ 'iifig' : '^\s*\\iifig{\(\w\+\)}.*$',
        \ 'input' : '^\s*\\input{\(.*\)}.*$',
        \   }

    let delim=repeat('%',50)

    for line in flines
        if line =~ pats.ii
            
            let iisec = substitute(line,pats.ii,'\1','g')

            let iilines=projs#filejoinlines({ "sec" : iisec })

            call add(lines,delim)
            call add(lines,'%% ' . line)
            call add(lines,delim)

            call extend(lines,iilines)

        elseif line =~ pats.iifig

            let fsec = substitute(line,pats.iifig,'\1','g')
            let fsec = 'fig.'.fsec

            let figlines=projs#filejoinlines({ "sec" : fsec })

            call add(lines,delim)
            call add(lines,'%% ' . line)
            call add(lines,delim)

            call extend(lines,figlines)

        elseif line =~ pats.input

            let if = substitute(line,pats.input,'\1','g')
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

    nnoremap <silent> ;;co :copen<CR>
    nnoremap <silent> ;;cc :cclose<CR>

    "nnoremap <silent> <F5> :cclose<CR>
    "nnoremap <silent> <F3> :cp<CR>
    "
    nnoremap <silent> <F1> :copen<CR>
    nnoremap <silent> <F2> :cclose<CR> 

    nnoremap <silent> <F4> :PrjMake<CR>
    nnoremap <silent> <F5> :PrjMakePrompt<CR>

    nnoremap <silent> <F6> :PrjSwitch<CR>
    
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

function! projs#init (...)

    let projsdir=''
    let projsid=''

    if projs#varexists('root')
        let projsdir  = projs#var('root')

        if projs#varexists('rootid')
            let projsid = projs#var('rootid')
        endif
        
    else
        let projsdir  = base#envvar('PROJSDIR')
        let projsid   = 'texdocs'
    endif

    if a:0 
        let projsid = a:1 
        let dir = base#path(projsid)

        call base#mkdir(dir)

        if isdirectory(dir)
            let projsdir = dir
        endif
    endif

    if strlen(projsid)
        call projs#var('rootid',projsid)
    endif

    let g:texlive={
        \  'TEXMFDIST'  : projs#tex#kpsewhich('--var-value=TEXMFDIST'),
        \  'TEXMFLOCAL' : projs#tex#kpsewhich('--var-value=TEXMFLOCAL'),
        \  }
    let g:pdfviewer = 'evince'

    let prefix="(projs#init) "
    call projs#echo("Initializing projs plugin, \n\t projsdir => " . projsdir ,{ "prefix" : prefix })

    call base#pathset({
        \   'projs' : projsdir,
        \   })


	call projs#update#datvars()

    let pdfout = projs#path([ 'pdf_built' ])
    call projs#var('pdfout',pdfout)
    call base#mkdir(pdfout)

    call projs#var('prjmake_opt','latexmk')

    "let texoutdir = projs#path([ 'builds' ])
    "call projs#var('texoutdir',texoutdir)

    let rootbuilddir = projs#path([ 'builds' ])
    call projs#var('rootbuilddir',rootbuilddir)
    call base#mkdir(rootbuilddir)

    if ! exists("proj") | let proj='' | endif
        
    let projsdirs=projs#var('projsdirs')
    call projs#var('projsdirslist',projsdirs)

    let varlist=sort(keys(s:projvars))
    call projs#var('varlist',varlist)

	call projs#update('list')

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

function! projs#rootbasename ()
    let root = projs#root()
    let bn   = fnamemodify(root,":p:h:t")

    return bn
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
        \ "pat"  : '^\(\w\+\)\.tex$' ,
        \ })

        "\ "pat"  : '^\(\w\+\)\.\(\w\+\)\.tex$' ,
        
    let exclude=projs#list#exclude()

    let nlist=[]
    let found={}
    for p in list
        let p = substitute(p,'^\(\w\+\)\.tex$','\1','g')

        if base#inlist(p,exclude)
            continue
        endif

        if !get(found,p,0)
            call add(nlist,p)
            let found[p]=1
        end
    endfor

    call projs#var('list',nlist)

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

function! projs#pathqw (s)
    let pa = base#qw(a:s)
    return projs#path(pa)

endfunction

function! projs#pathqwrf (s)
    let pa = base#qw(a:s)
    let f = projs#path(pa)
    let lines = []


    if filereadable(f)
        let lines = readfile(f)
    endif

    return lines

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

function! projs#varget (varname,...)
    
    if exists("s:projvars[a:varname]")
        let val = copy( s:projvars[a:varname] )
    else
        "call projs#warn("Undefined variable: " . a:varname)
        let val = ''
		if a:0
			unlet val
			let val = a:1
		endif
    endif

    return val
    
endfunction

function! projs#varset (varname, value)

	if !exists("s:projvars")
		let s:projvars={}
	endif
    if exists("s:projvars[a:varname]")
    	unlet s:projvars[a:varname]
	endif
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
        \   })

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
        \   })

    return files
endfunction

function! projs#warn (text)
    let prefix = "--PROJS--"
    call base#warn({ "text" : a:text, "prefix" : prefix })
    
endfunction

 
function! projs#renameproject(old,new)

 let old = a:old
 let new = a:new

 call projs#rootcd()
 call projs#proj#name(old)

 let files = projs#proj#files({ "exts" : [] })

 call projs#proj#name(new)
 
 for f in files
    let nf = substitute(f,'^'.old,new,'g')
    call rename(f,nf)

    let bn = fnamemodify(nf,':p:t')
    let sec = projs#secfromfile({ "file" : bn })
    if sec == '_main_'
        let lines=readfile(nf)
        let nlines=[]
        let changed=0
        for line in lines
            if line =~ '^\def\PROJ{'.old.'}'
                let line = '\def\PROJ{'.new.'}'
                let changed = 1
            endif
            call add(nlines,line)
        endfor
        if changed
            call writefile(nlines,nf)
        endif
    endif
 endfor

 call projs#update('list')
 
endfunction

""used in:
""  projs#new

function! projs#genperl(...)

 let pmfiles={}
 let proj = projs#var('proj')

 call extend(pmfiles, {
            \   'generate_pm' : g:paths['perlmod'] . '/lib/TeX/Project/Generate/' . proj . '.pm',  
            \   'generate_pl' : g:paths['projs']  . '/generate.' . proj . '.pl',  
            \   })
 
endfunction

function! projs#prjmakeoption (...)
    if a:0
        let opt = a:1
    else
        "let opt = 'latexmk'
        if projs#varexists('prjmake_opt')
            let opt  = projs#var('prjmake_opt')
        else
            let opts = projs#var('prjmake_opts')
            let opt  = base#getfromchoosedialog({ 
                \ 'list'        : opts,
                \ 'startopt'    : 'regular',
                \ 'header'      : "Available options for projs#build#run(...) are: ",
                \ 'numcols'     : 1,
                \ 'bottom'      : "Choose an option by number: ",
                \ })
        endif
        call projs#var('prjmake_opt',opt)
    endif
    return opt
endfunction

function! projs#prjmake (...)
    let opt = a:0 ? a:1 :  projs#prjmakeoption()
    call projs#build#run({ "opt" : opt })
endfunction

function! projs#prjmakeprompt (...)
    let opt = a:0 ? a:1 :  projs#prjmakeoption()
    call projs#build#run({ "opt" : opt, "prompt" : 1 })
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

function! projs#git (...)
    call projs#rootcd()
    
endfunction

function! projs#grep (...)
    let ref = {}
    if a:0 
		let pat = a:1
		if a:0 > 1 | let ref = a:2 | endif
	else
		let pat = input('Pattern to search for:','')
	endif

    call projs#rootcd()

    let exts  = base#qw('tex vim bib')
    let files = projs#proj#files ({ "exts" : exts })

    call base#grep({ 
        \ "pat"   : pat   ,
        \ "files" : files ,
        \ })
    
endfunction

function! projs#update (...)
	let opts = projs#varget('opts_PrjUpdate',base#qw('secnames list datvars'))

    if a:0
        let opt = a:1
    else
        let opt = base#getfromchoosedialog({ 
            \ 'list'        : opts,
            \ 'startopt'    : 'regular',
            \ 'header'      : "Available options are: ",
            \ 'numcols'     : 1,
            \ 'bottom'      : "Choose an option by number: ",
            \ })
    endif

    if opt == 'secnames'
        call projs#proj#secnames()
        call projs#proj#secnamesall()

    elseif opt == 'secnamesbase'
        call projs#varsetfromdat('secnamesbase')

    elseif opt == 'list'
        call projs#listfromfiles()
    elseif opt == 'datvars'
        call projs#update#datvars()
    elseif opt == 'loaded'
		call base#buffers#get()

		let bufs=base#var('bufs')
		let loaded={}

		for b in bufs
			let file = get(b,'shortname','')
			let path = get(b,'path','')
			let ext  = get(b,'ext','')

			if path != projs#root() | continue | endif

			let proj = projs#namefromfile({ 'file' : file })
			call extend(loaded,{ proj : 1 })
		endfor
		call projs#var('loaded',keys(loaded))

    endif
    
endfunction


function! projs#load (...)

    if a:0
        let opt = a:1
    endif

    if opt == ''
    elseif opt == 'tex'
        ProjsInit
        PrjView TEXREF
        PrjView latexref
    elseif opt == 'paps_phd'
    endif
    
endfunction

function! projs#exists (...)
    let proj = a:1
    let list = projs#list()

    if base#inlist(proj,list)
        return 1
    endif

    return 0
    
endfunction

