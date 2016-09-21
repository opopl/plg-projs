
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
    
		let sec = projs#proj#secname()
    let sec = get(a:000,0,sec)

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
        elseif basename =~ '\.\(\w\+\)\.bib$'
            let sec = '_unknown_'
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
        \   "prompt"  : 1, 
        \   }

    if a:0 
        let refadd = a:1 
        call extend(ref,refadd)
    endif
    let prompt = get(ref,'prompt',1)

    call projs#echo("Creating file:\n\t" . sec )

    let lines = []
    call extend(lines,get(ref,'add_lines_before',[]))

    let file = projs#secfile(sec)

    let secs = base#qw("preamble body")

    let projtype=projs#varget('projtype','regular')

"""newsec__main__
    if sec == '_main_'

      let file = projs#path([ proj.'.tex'])
      let sub = 'projs#newseclines#'.projtype.'#'.sec

      let lines = []
      exe 'let lines='.sub.'()'

"""newsec_bib
    elseif sec == 'bib'

        let bibstyle = input('Bibliography style:','unsrt')
        let bibfile  = input('Bibliography:','\PROJ.refs')

        call add(lines,'\phantomsection')
        "call add(lines,'\renewcommand\bibname{<++>}')

        call add(lines,'\addcontentsline{toc}{chapter}{\bibname}')

        call add(lines,'\bibliographystyle{'.bibstyle.'}')
        call add(lines,'\bibliography{'.bibfile.'}')
"""newsec_title
    elseif sec == 'title'
        call add(lines,' ')
        call add(lines,'\begin{titlepage}')
        call add(lines,' ')
        call add(lines,'\end{titlepage}')

"""newsec_index
    elseif sec == 'index'

        call add(lines,'\clearpage')
        call add(lines,'\phantomsection')
        call add(lines,'\addcontentsline{toc}{chapter}{\indexname}')
        call add(lines,'\printindex')

"""newsec_body
    elseif sec == 'body'

        call add(lines,' ')
        call add(lines,'%%file ' . sec)
        call add(lines,' ')

"""newsec_cfg
    elseif sec == 'cfg'

        call add(lines,' ')
        call add(lines,'%%file ' . sec)
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
        call add(lines,'%%file '. sec)
        call add(lines,' ')

        let ln  = projs#qw#rf('data tex preamble.tex')
        call extend(lines,ln)

    elseif sec == '_dat_'
    elseif sec == '_dat_defs_'
    elseif sec == '_vim_'
    elseif sec == '_bib_'

        call add(lines,' ')
        call add(lines,'"""file _vim_ ')
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
        call add(lines,'%%file '. sec)
        call add(lines,' ')
        call add(lines,'\nonstopmode')
        call add(lines,' ')

        let mf = projs#secfile('_main_')
        let ml = readfile(mf)

        call filter(ml,'v:val !~ "^%%file _main_"')

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
        call add(lines,'%%file ' . sec)
        call add(lines,' ')

        if prompt 
          let cnt = input('Continue adding? (1/0):',1)
  
          if cnt
              let addsec = input('Add sectioning? (1/0):',1)
              if addsec
                  let seccmd = input('Sectioning command: ','section','custom,tex#complete#seccmds')
  
                  let title = input('Title: ',sec)
                  let label = input('Label: ','sec:'.sec)
  
                  call add(lines,'\' . seccmd . '{'.title.'}')
                  call add(lines,'\label{'.label.'}')
                  call add(lines,' ')
              endif
          endif
        endif
 
    endif

    call extend(lines,get(ref,'add_lines_after',[]))

    call writefile(lines,file)

    if get(ref,'git_add')
        call base#sys("git add " . file)
    endif

    if get(ref,'view')
        exe 'split ' . file
    endif
    
endfunction

function! projs#help (...)
    echo ' '
    echo 'PROJS PLUGIN HELP'
    echo ' '

    let topics=base#qw('maps')

    let topic = base#getfromchoosedialog({ 
            \ 'list'        : topics,
            \ 'startopt'    : get(topics,0,''),
            \ 'header'      : "Available help topics are: ",
            \ 'numcols'     : 1,
            \ 'bottom'      : "Choose a help topic by number: ",
            \ })

    if topic == 'maps'
        let yn=input('Show projs#maps() ? (1/0):',1)
        if yn | call base#vim#showfun('projs#maps') | endif
    endif

endfunction

"
"
"""projs_new

"" projs#new()
"" projs#new(proj)
"" projs#new(proj,{ git_add : 1 })
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

 let yn=input('Continue? (1/0): ',1)
 if !yn | return 0 | endif

 let newopts=projs#var('PrjNew_opts',{})
  
 if a:0
     let proj     = a:1
     let projtype = 'regular'

     if (a:0 == 2 && ( base#type(a:2) == 'Dictionary'))
        call extend(newopts,a:2)
     endif

 endif

 let projtype   = projs#select#projtype()
 let projstruct = projs#select#projstruct()

 call projs#rootcd()

 if ! ( exists('proj') && strlen(proj) )
    let proj=input('Project name:','','custom,projs#complete')
 endif

 if ! strlen(proj)
     call base#warn({ 'text' : 'no project name provided' })
     return 0 
 endif
 
 if projs#ex(proj)
    let rw = input('Project already exists, rewrite (1/0)?: ',0)

    if !rw | return 0 | endif
 endif

  call projs#proj#name(proj)
  call projs#var('projtype',projtype)

  let texfiles =  projs#update#texfiles()

  let nsecs_h = {
      \ "single_file"   : "_main_",
      \ "da_qa_report"  : "_main_ preamble body tests_run ",
      \ "regular"       : " _main_ preamble body cfg bib index",
      \ }

  let nsecs_s = get(nsecs_h,projtype,'')

  if projtype == 'da_qa_report'
    let vms   = input('Tested VMs:','winxp1 win7x64n1')
    let tests = input('Tests Run:','trial_forcetest licensed_forcetest LCS_license_generate')
    let nsecs_s.=vms
  endif

  let nsecs_s = input('Sections to be created:',nsecs_s)

  let nsecs = base#qw(nsecs_s)

  for sec in nsecs
     call projs#newsecfile(sec)
  endfor

  call projs#proj#git_add()
  
  call base#echoredraw('Created new project: ' . proj)
  
  call base#var('proj',proj)
  
  call projs#listadd(proj)
  
  let loadmain=input('Load the main project file? (1/0): ', 1)
  if loadmain 
    VSECBASE _main_
  endif
  
  TgUpdate projs_this
  call projs#update('list')

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
        let sec  = matchstr(a:1,'^\w\+\.\zs\w\+\ze')
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

    let f = projs#secfile('_osecs_')
    call projs#varset('secorderfile',f)

    if ! strlen(sec)
        let sec='_main_'
    endif

    call projs#varset('secname',sec)
    call projs#varset('proj',proj)
    
    call projs#opensec(projs#var('secname'))
 
    if (exists("*make#makeprg"))
        call make#makeprg('projs_latexmk',{ 'echo' : 0 })
    endif

    let vimf = projs#path([ proj . '.vim' ])
    if filereadable(vimf)
        exe 'source ' . vimf
    endif

    TgSet projs_this
    TgAdd plg_projs

    let loaded=projs#varget('loaded',[])

    call add(loaded,proj)
    call projs#varset('loaded',loaded)

		let u='piclist secnames usedpacks'
    call projs#update_qw(u)

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
  "
  setlocal iminsert=0

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
	let u='piclist secnames usedpacks'
  call projs#update_qw(u)

  let sec = 'body'
  let sec = input('Section to open:',sec,'custom,projs#complete#secnames')

  call projs#opensec(sec)
  
endfunction

"call projs#onload ()
"call projs#onload ({ 'proj' : proj })

function! projs#onload (...)
  let ref = {}
  if a:0 | let ref = a:1 | endif

  let b:projs_onload_done=1

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  setlocal ts=2
	"-------- needed for keymapping
  setlocal iminsert=0
	"-------- needed for tags
  setlocal isk=@,48-57,_,128-167,224-235

  TgAdd projs_this
  TgAdd plg_projs

  StatusLine projs

  call projs#maps()
  
endfunction

function! projs#opensec (...)
 let proj = projs#proj#name()

 if a:0==1
    let sec=a:1
 else
    let sec=projs#select#sec()
 endif

 if !projs#sec#exists(sec)
    let cnt = input('Section does not exist, continue? (1/0):',1)
    if !cnt | return | endif
 endif

  call projs#varset("secname",sec)

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
    call base#plg#loadvars('projs')
    let vars = projs#varget('vars',{})

    for [k,v] in items(vars)
      call projs#varset(k,v)
    endfor
endf

function! projs#warn (text)
    let prefix = "--PROJS--"
    call base#warn({ "text" : a:text, "prefix" : prefix })
    
endfunction

function! projs#echo(text,...)

    let prefix='--PROJS--'
    if a:0
        let opts=a:1
        let prefix=get(opts,'prefix',prefix)
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
        \ 'text' : "projs#root()     => " . projs#root(),
        \ 'indentlev' : indentlev, })

    call base#echo({ 
        \ 'text' : "projs#rootid()   => " . projs#rootid(),
        \ 'indentlev' : indentlev, })

    call base#echo({ 
        \ 'text' : "$PROJSDIR => " . base#envvar('PROJSDIR'), 
        \ 'indentlev' : indentlev, })

    call base#echo({ 'text' : "Projects PDF dir: " } )
    call base#echo({ 
        \ 'text' : "pdffin => " . projs#var('pdffin'),
        \ 'indentlev' : indentlev, })

    call base#echo({ 'text' : "Project type: " } )
    call base#echo({ 
        \ 'text'      : "projtype => " . projs#varget('projtype',''),
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
    let loaded=projs#var('loaded')
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

            let iisec   = substitute(line,pats.ii,'\1','g')

            let iilines = projs#filejoinlines({ "sec" : iisec })

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

    nnoremap <buffer><silent> <F1> :PrjMake build_pdflatex<CR>
    nnoremap <buffer><silent> <F2> :PrjMake single_run<CR>
    nnoremap <buffer><silent> <F3> :PrjMake latexmk<CR>
    nnoremap <buffer><silent> <F4> :PrjMake<CR>
    nnoremap <buffer><silent> <F5> :PrjMakePrompt<CR>

    nnoremap <buffer><silent> <F6> :PrjSwitch<CR>
    nnoremap <buffer><silent> <F7> :PrjPdfView<CR>
    nnoremap <buffer><silent> <F8> :PrjUpdate<CR>
    nnoremap <buffer><silent> <F9> :OMNIFUNC<CR>
    nnoremap <buffer><silent> <F10> :TgUpdate<CR>
    
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

    call projs#initvars()
    call projs#init#au()

    let rootid = get(a:000,0,'')
    let [root,rootid] = projs#init#root(rootid)
    

    let prefix="(projs#init) "
    call projs#echo("Initializing projs plugin, \n\t projsdir => " . root ,{ "prefix" : prefix })
  
    let pdfout = projs#path([ 'pdf_built' ])

    let pdffin = exists('$PDFOUT') ? $PDFOUT : base#qw#catfile('C: out pdf')

    call projs#var('pdffin',pdffin)
    call base#mkdir(pdffin)

    call projs#var('prjmake_opt','latexmk')

    call projs#var('pdfout',pdfout)
    call base#mkdir(pdfout)

    let rootbuilddir = projs#path([ 'builds' ])
    call projs#var('rootbuilddir',rootbuilddir)
    call base#mkdir(rootbuilddir)

    if ! exists("proj") | let proj='' | endif
        
    let projsdirs=projs#var('projsdirs')
    call projs#var('projsdirslist',projsdirs)

    " update list of projs plugin variables
    call projs#update#varlist()

    " update list of projects
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

function! projs#rootid ()
    return projs#varget('rootid','')
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
        \ "subdirs" : 0                      ,
        \ "pat"  : '^\(\w\+\)\.tex$' ,
        \ })
        
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

function! projs#piclist ()
  let list = projs#varget('piclist',[])
  return list
endf    

function! projs#list ()

    let list=projs#varget('list',[])
    if ! len(list)
        let list = projs#listfromfiles()
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

function! projs#vars (...)
  let vars =  base#varget('projs_vars',{})
  return vars
endfunction

function! projs#varlist (...)
  let vars = projs#var('varlist')
  return vars
endfunction

function! projs#var (...)
    if a:0 == 1
        let var = a:1
        return base#varget('projs_'.var)
    elseif a:0 == 2
        let var = a:1
        let val = a:2
        return base#varset('projs_'.var,val)
    endif
endfunction


function! projs#varset (varname, value)
  call base#varset('projs_'.a:varname,a:value)
endfunction

function! projs#varecho (varname)
    echo projs#var(a:varname)
endfunction

function! projs#varget (varname,...)
    if a:0
      let val = base#varget('projs_'.a:varname,a:1)
    else
      let val = base#varget('projs_'.a:varname)
    endif
   
    return val
    
endfunction


function! projs#varexists (varname)
    if base#varexists('projs_'.a:varname)
        return 1
    endif
    return 0

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

function! projs#update_qw (s)
  let s = a:s 
  let opts = base#qwsort(s)

  for o in opts
    call projs#update(o)
  endfor

endfunction

function! projs#update (...)
  let opts = projs#varget('opts_PrjUpdate',base#qw('secnames list datvars'))
  let proj = projs#proj#name()

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

		let o = { "prefix" : "(proj: ".proj.") "  }
    if opt == 'secnames'
				call projs#echo("Updating list of sections",o)

        call projs#proj#secnames()
        call projs#proj#secnamesall()

    elseif opt == 'piclist'
				call projs#echo("Updating list of pictures",o)

        let pdir = projs#path(['pics',proj])
        let piclist = base#find({ 
            \ "dirs"    : [pdir],
            \ "qw_exts" : 'jpg png eps',
            \ "rmext" : 1,
            \ "relpath" : 1,
            \ })
        call projs#var('piclist',piclist)

    elseif opt == 'secnamesbase'
				call projs#echo("Updating list of base sections",o)

        call projs#varsetfromdat('secnamesbase')

    elseif opt == 'list'
				call projs#echo("Updating list of projects")

        call projs#listfromfiles()

    elseif opt == 'usedpacks'
				call projs#echo("Updating list of used TeX packages",o)

        call projs#update#usedpacks()

    elseif opt == 'varlist'
				call projs#echo("Updating list of PROJS variables")

        call projs#update#varlist()

    elseif opt == 'datvars'
        call projs#update#datvars()

    elseif opt == 'loaded'
				call projs#echo("Updating list of loaded projects")

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

