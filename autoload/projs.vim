
" projs#sec#file (sec)
"

function! projs#namefromfile (...)
  let ref = {}
  if a:0 | let ref = a:1 | endif

  let file = get(ref,'file','')
  let bname = fnamemodify(file,':p:t')
  let name = substitute(bname,'^\(\w\+\)\..*$','\1','g')

  return name

endfunction

"call projs#secfromfile ({ 
"   \ "file" : file, 
"   \ "type" : "basename", 
"   \ "proj" : proj 
"   \ })

function! projs#secfromfile (...)
    let ref = {}
    if a:0 | let ref = a:1 | endif

    let proj = projs#proj#name()

    let file = get(ref,'file','')
    let type = get(ref,'type','basename')
    let proj = get(ref,'proj',proj)

    let sec = ''
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


function! projs#help (...)
    echo ' '
    echo 'PROJS PLUGIN HELP'
    echo ' '

    let topics = base#qw('maps')

    let topic = base#getfromchoosedialog({ 
            \ 'list'        : topics,
            \ 'startopt'    : get(topics,0,''),
            \ 'header'      : "Available help topics are: ",
            \ 'numcols'     : 1,
            \ 'bottom'      : "Choose a help topic by number: ",
            \ })

    if topic == 'maps'
        let yn = input('Show projs#maps() ? (1/0):',1)
        if yn | call base#vim#showfun('projs#maps') | endif
    endif

endfunction

if 0
  projs_new
  
  projs#new()
  projs#new(proj)
  projs#new(proj,{ git_add : 1 })
endif

function! projs#new (...)
 call base#echoprefix('(projs#new)')

 let delim = repeat('-',50)
 let proj  = ''

 echo delim
 echo " "
 echo "This will create a new TeX project skeleton "
 echo "    in projects' root directory: " . projs#root() 
 echo " "
 echo delim

 let yn = input('Continue? (1/0): ',1)
 if !yn | return 0 | endif

 let newopts = projs#varget('PrjNew_opts',{})
  
 if a:0
     let proj     = a:1
     let projtype = 'regular'

     if (a:0 == 2 && ( base#type(a:2) == 'Dictionary'))
        call extend(newopts,a:2)
     endif
 else
     if !strlen(proj)
        let proj = input('New project name:','','custom,projs#complete')
     endif
 endif

 if ! strlen(proj)
     call base#warn({ 'text' : 'no project name provided' })
     return 0 
 endif

 let projtype   = projs#select#projtype()
 let projstruct = projs#select#projstruct()

 call projs#rootcd()
 
 if projs#ex(proj)
    let rw = input('Project already exists, rewrite (1/0)?: ',0)

    if !rw | return 0 | endif
 endif

  call projs#proj#name(proj)
  call projs#varset('projtype',projtype)

  let texfiles =  projs#update#texfiles()

  let nsecs_h = {
      \ "single_file"   : "_main_",
      \ "regular"       : join(base#varget('projs_secs_regular',[]),' '),
      \ }
  let nsecs_s = get(nsecs_h,projtype,'')
  let nsecs_s .= ' _vim_ '

  let nsecs_s = input('Sections to be created:',nsecs_s)
  let nsecs = base#qw(nsecs_s)

  for sec in nsecs
     call projs#sec#new(sec)
  endfor

  call projs#proj#git_add()
  
  call base#echoredraw('Created new project: ' . proj)
  
  call base#varset('proj',proj)
  
  call projs#listadd(proj)
  
  let loadmain = input('Load the main project file? (1/0): ', 1)
  if loadmain 
    VSECBASE _main_
  endif
  
  TgUpdate projs_this
  call projs#update('list')

  call base#echoprefixold()
    
  return 1

endf

function! projs#pylib ()
  let pylib = base#qw#catpath('plg','projs python lib')
  return pylib
endfunction

" Usage
"
"   projs#selectproject ()
"   projs#selectproject (pat)
"
" Call tree
"   Called by
"     projs#viewproj

function! projs#selectproject (...)
    
    if a:0
      let pat  = a:1
    endif

    let list = projs#list()
    let data_h = []
    for p in list
      call add(data_h, { 'proj' : p })
    endfor

    let lines = pymy#data#tabulate({
      \ 'data_h'  : data_h,
      \ 'headers' : [ 'proj' ],
      \ })

    "call base#buf#open_split({ 'lines' : lines })

    let msg_a = [
      \ "select project: ", 
      \ ]
    let msg = join(msg_a,"\n")
    
    let proj = base#input_we(msg,'',{ 'complete' : 'custom,projs#complete' })
    return proj
    
endfunction

if 0
 Purpose
   view project
 Usage
   call projs#viewproj (proj)
   PV 
   PV proj
 Call tree
   Calls:
     projs#rootcd
     projs#new
     projs#selectproject
     projs#proj#name
     projs#sec#file
     projs#exists
endif

function! projs#viewproj (...)

    call projs#rootcd()

    let sec = ''
    let proj = ''
    if a:0
        let proj = matchstr(a:1,'^\zs\w\+\ze')
        let sec  = matchstr(a:1,'^\w\+\.\zs\w\+\ze')
    else
        let proj = projs#selectproject()
    endif

    if ! projs#exists(proj)
        let o = input('Project ' . proj . ' does not exist, create new? (1/0):',1)
        if o
            call projs#new(proj)
            return 1
        endif
    endif

    call projs#proj#name(proj)

    let f = projs#sec#file( '_osecs_' )
    call projs#varset( 'secorderfile', f)

    if ! strlen(sec)
        let sec = '_main_'
    endif

    call projs#varset('secname',sec)
    call projs#varset('proj',proj)
    
    call projs#sec#open(sec)
 
    if (exists("*make#makeprg"))
        call make#makeprg('projs_latexmk',{ 'echo' : 0 })
    endif

    let vimf = projs#path([ proj . '.vim' ])
    if filereadable(vimf)
        call projs#echo('Found project vim file, executing:' . "\n\t" . vimf)
        exe 'source ' . vimf
    endif

    TgSet projs_this
    TgAdd plg_projs

    let loaded = projs#varget('loaded',[])

    call add(loaded, proj)
    call projs#varset('loaded',loaded)

    let u = 'piclist secnames usedpacks'
    call projs#update_qw(u)

endfun

fun! projs#complete (...)

  let comps = []
  let comps = projs#list()

  return join(comps,"\n")
endf


fun! projs#checksecdir()

    call projs#varset('secdirexists',0)

    let proj = projs#var('proj')
    let dir  = projs#path([ proj ])

    if isdirectory(dir)
        call projs#var('secdirexists',1)
    endif

endf

function! projs#insert (...)
  let ins = get(a:000,0,'')

  let proj = projs#proj#name()

  let acts = base#varget('projs_opts_PrjInsert',[])
  let acts = sort(acts)

  if  strlen(ins)
    let sub = 'projs#insert#'.ins
    exe 'call '.sub.'()'
  else
    let desc = base#varget('projs_desc_PrjInsert',{})
    let info = []
    for act in acts
      call add(info,[ act, get(desc,act,'') ])
    endfor
    let proj = projs#proj#name()
    let lines = [ 
      \ 'Current project:' , "\t" . proj,
      \ 'Current section:' , "\t" . projs#buf#sec(),
      \ 'Possible PrjInsert actions: ' 
      \ ]

    call extend(lines, pymy#data#tabulate({
      \ 'data'    : info,
      \ 'headers' : [ 'act', 'description' ],
      \ }))

    let s:obj = { 'proj' : proj }
    function! s:obj.init (...) dict
      let proj = self.proj
      let hl = 'WildMenu'
      call matchadd(hl,'\s\+'.proj.'\s\+')
      call matchadd(hl,proj)
    endfunction
    
    let Fc = s:obj.init

    call base#buf#open_split({ 
      \ 'lines'    : lines ,
      \ 'cmds_pre' : ['resize 99'] ,
      \ 'Fc'       : Fc,
      \ })
    return
  endif


  
endfunction

function! projs#htlatex (...)
    call projs#build#run({ "opt" : 'build_htlatex' })
endfunction

function! projs#visual (...)
  let start = get(a:000, 0, '')
  let end   = get(a:000, 1, '')
  let act   = get(a:000, 2, '')

  let sub = 'projs#visual#' . act . '(start,end)'
  exe 'call ' . sub
  
endfunction

function! projs#buf_cmd (...)
  let act = get(a:000,0,'')

  if !exists("b:sec")
    return
  endif

  let acts = base#varget('projs_opts_PrjBuf',[])
  let acts = sort(acts)

  if ! strlen(act)
    let desc = base#varget('projs_desc_PrjBuf',{})
    let info = []
    for act in acts
      call add(info,[ act, get(desc,act,'') ])
    endfor
    let proj = projs#proj#name()
    let sec  = b:sec
    let lines = [ 
      \ 'Current project:' , "\t" . proj,
      \ 'Current section:' , "\t" . sec,
      \ 'Possible PrjBuf actions: ' 
      \ ]

    call extend(lines, pymy#data#tabulate({
      \ 'data'    : info,
      \ 'headers' : [ 'act', 'description' ],
      \ }))

    let s:obj = { 'proj' : proj }
    function! s:obj.init (...) dict
      let proj = self.proj
      let hl = 'WildMenu'
      call matchadd(hl,'\s\+'.proj.'\s\+')
      call matchadd(hl,proj)
    endfunction
    
    let Fc = s:obj.init

    call base#buf#open_split({ 
      \ 'lines'    : lines ,
      \ 'cmds_pre' : ['resize 99'] ,
      \ 'Fc'       : Fc,
      \ })
    return
  endif

  let sub = 'projs#buf_cmd#'.act

  exe 'call '.sub.'()'
endfunction

function! projs#gui (...)
  let act = get(a:000,0,'')

  let acts = base#varget('projs_opts_PrjGui',[])
  let acts = sort(acts)
  if ! strlen(act)
    let desc = base#varget('projs_desc_PrjGui',{})
    let info = []
    for act in acts
      call add(info,[ act, get(desc,act,'') ])
    endfor
    let proj = projs#proj#name()
    let lines = [ 
      \ 'Current project:' , "\t" . proj,
      \ 'Possible PrjGui actions: ' 
      \ ]

    call extend(lines, pymy#data#tabulate({
      \ 'data'    : info,
      \ 'headers' : [ 'act', 'description' ],
      \ }))

    let s:obj = { 'proj' : proj }
    function! s:obj.init (...) dict
      let proj = self.proj
      let hl = 'WildMenu'
      call matchadd(hl,'\s\+'.proj.'\s\+')
      call matchadd(hl,proj)
    endfunction
    
    let Fc = s:obj.init

    call base#buf#open_split({ 
      \ 'lines'    : lines ,
      \ 'cmds_pre' : ['resize 99'] ,
      \ 'Fc'       : Fc,
      \ })
    return
  endif

  exe printf('call projs#gui#%s()',act)

endfunction

function! projs#action (...)
  let act = get(a:000,0,'')

  let acts = base#varget('projs_opts_PrjAct',[])
  let acts = sort(acts)
  if ! strlen(act)
    let desc = base#varget('projs_desc_PrjAct',{})
    let info = []
    for act in acts
      call add(info,[ act, get(desc,act,'') ])
    endfor
    let proj = projs#proj#name()
    let lines = [ 
      \ 'Current project:' , "\t" . proj,
      \ 'Possible PrjAct actions: ' 
      \ ]

    call extend(lines, pymy#data#tabulate({
      \ 'data'    : info,
      \ 'headers' : [ 'act', 'description' ],
      \ }))

    let s:obj = { 'proj' : proj }
    function! s:obj.init (...) dict
      let proj = self.proj
      let hl = 'WildMenu'
      call matchadd(hl,'\s\+'.proj.'\s\+')
      call matchadd(hl,proj)
    endfunction
    
    let Fc = s:obj.init

    call base#buf#open_split({ 
      \ 'lines'    : lines ,
      \ 'cmds_pre' : ['resize 99'] ,
      \ 'Fc'       : Fc,
      \ })
    return
  endif

  let sub = 'projs#action#'.act

  exe 'call '.sub.'()'

endfunction

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

  call projs#sec#open(sec)
  
endfunction

if 0
  call projs#onload ()
  call projs#onload ({ 'proj' : proj })
  
  call tree
     calls
       projs#maps
     called by
       projs#buf#onload_tex_tex
         projs_ftplugin_tex
endif

function! projs#onload (...)
  let ref = {}
  if a:0 | let ref = a:1 | endif

  let msg = [ printf('basename: %s', b:basename ) ]
  let prf = { 'plugin' : 'projs', 'func' : 'projs#onload' }
  call base#log(msg, prf)

  "-------- needed for keymapping
  setlocal iminsert=0

  "-------- needed for tags
  setlocal isk=@,48-57,_,128-167,224-235,.,:

  setlocal ts=2

  TgSet projs_this

  let done = base#eval("b:projs_onload_done")
  if done | return | endif

  let b:projs_onload_done = 1

  call projs#maps()
    
  let prf = { 'prf' : 'projs#onload' }
  call base#log([
    \ 'ref => ' . base#dump(ref),
    \ ],prf)

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  StatusLine projs

  call projs#exe_latex('pdflatex')

  let vf = projs#sec#file('_vim_')
  call base#vimfile#source({ 'files' : [vf] })

endfunction

function! projs#exe_latex (...)
  let exe_latex = get(a:000,0,'pdflatex')

  let makeprg = make#varget('makeprg','projs_single_run')

  if a:0
    call projs#varset('exe_latex',exe_latex)
    call make#makeprg(makeprg)
  else
    let exe_latex = projs#varget('exe_latex',exe_latex)
  endif
  
 return exe_latex

endfunction


function! projs#gensecdat (...)
 
 let f = projs#path([ proj . '.secs.i.dat' ])
 call projs#varset('secdatfile',f)

 let datlines=[]

 for line in projs#var('secnames')
   if ! base#inlist(line,base#qw("_main_ _dat_ _osecs_ _bib_ _pl_ "))
      call add(datlines,line)
   endif
 endfor

 call writefile(datlines,projs#varget('secdatfile'))

endf

fun! projs#opensecorder()
 
  let f = projs#path([proj . '.secorder.i.dat' ])

  call projs#varset('secorderfile',f)
  exe 'tabnew ' . projs#var('secorderfile')

  MakePrg projs

endf

 
"" Remove the project 
""  This function does not affect the current value of proj 
""          if proj is different from the project being removed.
""          On the other hand, if proj is the project requested to be removed,
""     proj is unlet in the end of the function body

" former DC_PrjRemove
"
if 0
  call in 
    plugin/projs_init.vim
endif


function! projs#initvars (...)
    call base#plg#loadvars('projs')
    let vars = projs#varget('vars',{})

    for [k,v] in items(vars)
      call projs#varset(k,v)
    endfor
endf

function! projs#warn (text)
    call base#warn({ "text" : a:text, "plugin" : 'projs' })
endfunction

function! projs#echo(text,...)

  let opts = get(a:000,0,{})
 
  let prf = { 'plugin' : 'projs'}
  call extend(prf,opts)
  call base#log(a:text,prf)

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

    """ jfile handling ----------------------
    let jdir = projs#path(['joins'])
    call base#mkdir(jdir)
    let jfile = base#file#catfile([ jdir, proj . '.tex' ])
    let jfile = get(ref,'jfile',jfile)

    let write_jfile = get(ref,'write_jfile',0)
    """ end jfile handling ----------------------

    let sf      = {}
    let sf[sec] = projs#sec#file(sec)
    let f       = sf[sec]

    if !filereadable(f)
      return []
    endif

    let flines = readfile(f)
    let lines  = []

    let pats = {
        \ 'ii'    : '^\s*\\ii{\(.\+\)}.*$',
        \ 'iifig' : '^\s*\\iifig{\(.\+\)}.*$',
        \ 'input' : '^\s*\\input{\(.*\)}.*$',
        \   }

    let delim = repeat('%',50)

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

        if write_jfile
          echo 'Writing joined lines into: ' 
          echo '  ' . jfile
      
          call writefile(lines,jfile)
        endif

    endif

    return lines

endf

function! projs#maps (...)
  let ref = get(a:000,0,{})

  let exts = get(ref,'exts',[])
  let ext  = get(ref,'ext','tex')

  if len(exts)
    for ext in exts
      call projs#maps({ 'ext' : ext })
    endfor
    return 
  endif

  let msg = [ printf('basename: %s', b:basename ) ]
  let prf = { 'plugin' : 'projs', 'func' : 'projs#maps' }
  call base#log(msg, prf)

  let maps = {}
  if ext == 'tex'
    let maps = {
          \ 'nnoremap' :
            \ {
            \  ';;'    : 'PrjAct pwg_insert_img'  ,
            \  '<F1>'  : 'PrjAct async_build_pwg'  ,
            \  ';ab'   : 'PrjAct async_build_bare'  ,
            \  ';bb'   : 'PrjAct async_build_perl'  ,
            \  '<F2>'  : 'PrjBuild Cleanup'    ,
            \  '<F3>'  : 'copen'               ,
            \  '<F4>'  : 'cclose'              ,
            \  '<F5>'  : 'PrjDB thisproj_data' ,
            \  '<F6>'  : 'PrjDB buf_data'      ,
            \  '<F7>'  : 'call projs#git#save()' ,
            \  '<F8>'  : 'PrjListSecs'         ,
            \  '<F10>' : 'TgUpdate projs_this' ,
            \  ';tp'   : 'TgUpdate projs_this' ,
            \  ';wp'   : 'tag preamble'        ,
            \  ';wm'   : 'tag f_main'          ,
            \  ';wb'   : 'tag body'            ,
            \  '<S-T>' : 'PrjDB fill_tags'   ,
            \  '<S-Y>' : 'PrjAct html_out_view'   ,
            \  '<C-A>' : 'PrjAct git_add_texfiles'   ,
            \  '<C-M>' : 'PrjAct maps_update'   ,
            \  '<C-H>' : 'PrjAct async_build_htlatex'   ,
            \ },
         \ 'vnoremap' : {
              \  '?'      : 'PrjVisual help'            ,
              \  '<F1>'   : 'VENCLOSE verbatim'         ,
              \  '<F2>'   : 'PrjVisual ii_to_new_secs'  ,
            \ }
          \ }

    call extend(maps.nnoremap,{
            \  ';v'    : 'call projs#pdf#view("","evince")',
            \  ';k'    : 'call projs#pdf#view("","okular")',
            \ })

    call base#varset('projs_maps',maps)
  
  endif

  for [ map, mp ] in items(maps)
    call base#buf#map_add(mp,{ 'map' : map })
  endfor

  call base#rdw('OK: projs#maps')

  
endfunction

function! projs#builddir (...)
    let qw       = get(a:000,0,'')
    let qw_a     = split(qw,' ')

    let sub_path = ''
    
    if len(qw)
      let sub_path = join(qw_a, base#file#sep() )
    endif

    let proj     = projs#proj#name()
    let broot    = projs#varget('rootbuilddir','')
    let builddir = base#file#catfile([ broot, proj ])

    if len(sub_path)
      let builddir = base#file#catfile([ builddir, sub_path ])
    endif

    return builddir
endfunction

"""projs_init

"call projs#init ()       -  ProjsInit     - use environment variable PROJSDIR
"call projs#init (dirid)  -  ProjsInit DIRID - specify custom projects' directory, full path is base#path(DIRID)
"
"
" ProjsInit DIRID
"

if 0
  Call tree
    Used by 
      ProjsInit
    Called in
      plugin/projs_init.vim
  Usage
    call projs#init()
    call projs#init(rootid)
endif

function! projs#init (...)
    let rootid = projs#varget('rootid','')
    let rootid = get(a:000,0,rootid)

    let l:start = localtime()
    let msg = [ 'start' ]
    let prf = { 'plugin' : 'projs', 'func' : 'projs#init' }
    call base#log(msg,prf)

    " -------------------------------------------------
    " load variables from the corresponding dat files
    " load: 
    "   data/list/vars.i.dat
    "
    "   all other dat files in data/list, data/dict subdirs
    call projs#initvars()
    " -------------------------------------------------

    " plg_projs augroup - autocommand group
    call projs#init#au()

    " init projs variables: 
    "   templates_tex, templates_vim
    call projs#init#templates()

    let [ root, rootid ] = projs#init#root(rootid)

    if !strlen(rootid)
      call projs#warn('rootid is NOT defined! Aborting init.')
      return
    endif

    let ifile = projs#path([ '_init_.vim' ])
    if filereadable(ifile)
      exe 'so '.ifile
    endif

    let vars = projs#varget('init_vars',[])
    for x in vars
      call projs#init#var(x)
    endfor

    call projs#db#create_tables()

    if ! exists("proj") | let proj='' | endif

    " update list of projs plugin variables
    call projs#update#varlist()

    " update list of projects
    call projs#update('list')


    "MenuAdd projs

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

function! projs#xmlfile (...)
  let root = projs#root()
  let xmlfile = join([root,'projs.xml'], '/')
  return xmlfile
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

function! projs#url_dir ()
  let url_dir = join([ projs#root(), 'html', 'url' ],'/')
  return url_dir
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
    let file = projs#list_dat()
    let list = base#readdatfile({ 
            \ "file" : file, 
            \ "type" : "List", 
            \ "sort" : 1,
            \ "uniq" : 1,
            \ })
    call projs#var("list",list)
    return list
endf    

function! projs#list_dat ()
    let file = ap#file#catfile([ projs#root(), 'PROJS.i.dat' ])
endfunction

function! projs#list_write2dat ()
    let file = projs#list_dat()
    let list = projs#var("list",[])

    if !len(list)
      call projs#listfromfiles()
    endif
endfunction

function! projs#listfromfiles ()
    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    let msg = ['start']
    let prf = {'plugin' : 'projs', 'func' : 'projs#listfromfiles'}
    call base#log(msg,prf)
    let l:start=localtime()
    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    "
    let root = projs#root()

    let list = base#find({ 
        \ "dirs" : [ root ]                  ,
        \ "ext"  : [ "tex" ]                 ,
        \ "relpath" : 1                      ,
        \ "subdirs" : 0                      ,
        \ "pat"     : '^(\w+)\.tex$'         , 
        \ })
        
    let exclude = projs#list#exclude()

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

    call projs#varset('list',nlist)

    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    let l:elapsed = localtime() - l:start
    let msg = ['end, elapsed = ' . l:elapsed]
    let prf = {'plugin' : 'projs', 'func' : 'projs#listfromfiles'}
    call base#log(msg,prf)
    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    return nlist
endf    

function! projs#piclist ()
  let list = projs#varget('piclist',[])
  return list
endf    

if 0
  projs#list

  Purpose:
    get the list of projects
  Usage:
    let list = projs#list ()
    let list = projs#list ({ 'get' : 'fromfiles' })
    let list = projs#list ({ 'get' : 'fromvar' })
  Returns:
    array - list of projects
  Call tree:
    calls:
      
    called by:
      
endif

function! projs#list (...)
    let ref = get(a:000,0,{})

    let gt = get(ref,'get')

    let gts = base#qw('fromdb fromvar fromfiles')

    let list = []
    while !len(list)
      let gt = remove(gts,-1)

      if gt == 'fromvar'
        let list = projs#varget('list',[])

      elseif gt == 'fromdb'
        let list = projs#db#list()

      elseif gt == 'fromfiles'
        let list = projs#listfromfiles()
      endif

      break
    endw

    return copy(list)
endf    

function! projs#listadd (proj)
    let list = projs#list()

    if ! projs#ex(a:proj)
        call add(list,a:proj)
    endif

    call projs#varset("list",list)
    
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
    echo projs#varget(a:varname)
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

"Usage
"  Rename current project to 'new':
"    call projs#renameproject(new)
"
"  Rename project from 'old' to 'new':
"    call projs#renameproject(old,new)

function! projs#renameproject(...)

 let new = get(a:000,0,'')
 let old = get(a:000,1,projs#proj#name())

 if !strlen(new)
      let new = input('New project name:','','custom,projs#complete')
 endif

 call projs#rootcd()
 call projs#proj#name(old)

 let files = projs#proj#files()

 call projs#proj#name(new)
 
 for f in files
    let nf = substitute(f,'^'.old,new,'g')
    call rename(f,nf)

    let bn = fnamemodify(nf,':p:t')
    let sec = projs#secfromfile({ "file" : bn })
    if sec == '_main_'
        let lines = readfile(nf)
        let nlines = []
        let changed = 0
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
            let opt  = projs#varget('prjmake_opt','')
        else
            let opts = projs#varget('prjmake_opts',[])
            let opt  = base#getfromchoosedialog({ 
                \ 'list'        : opts,
                \ 'startopt'    : 'regular',
                \ 'header'      : "Available options for projs#build#run(...) are: ",
                \ 'numcols'     : 1,
                \ 'bottom'      : "Choose an option by number: ",
                \ })
        endif
        call projs#varset('prjmake_opt',opt)
    endif
    return opt
endfunction

"Usage:
"   call projs#prjmake ()
"   call projs#prjmake (opt)
"     where opt 
"
"Call tree:
"   Calls:
"     projs#build#run
"
"   Called by:
"     PrjMake

function! projs#prjmake (...)
    let opt = a:0 ? a:1 :  projs#prjmakeoption()
    call projs#build#run({ "opt" : opt })
endfunction
    " -------------------------------------------------

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

 let prf={ 'prf' : 'projs#buildnum' }
 call base#log([
  \ 'proj => ' . proj ,
  \ ],prf)
        
 """" --------------------- get build number, initialize output pdf directory
 let pdfout = projs#path([ 'pdf_built' ])
 call base#mkdir(pdfout)

 let bnum = 1
 let pdfs = base#find({ 
    \ "dirs" : [ pdfout ], 
    \ "exts" : ["pdf"],
    \ "relpath" : 1,
    \ "pat"     : '^'.proj.'(\d+)\.pdf',
    \ })

 let bnums = []
 let pat = proj.'\(\d\+\)\.pdf'
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

 let prf={ 'prf' : 'projs#setbuildvars' }
 call base#log([
  \ 'ref => ' . base#dump(ref),
  \ ],prf)
        
 let proj = projs#proj#name()

 let bnum      = projs#buildnum()
 let texoutdir = base#file#catfile([ projs#builddir(), bnum ])

 call base#mkdir(texoutdir)
 call projs#varset('texoutdir',texoutdir)

 let texmode    = projs#varget('texmode')
 let texjobname = proj

 let buildmode    = projs#varget('buildmode','')

 call projs#varset('texjobname',texjobname)
 call projs#varset('buildnum',bnum)

  let txt =''
  let txt.= "\n" . '---------- projs#setbuildvars(...)--------'
  let txt.= "\n" . 'Setting latex build-related options:'
  let txt.= "\n" . ' '
  let txt.= "\n" . '  buildnum         => '  . bnum
  let txt.= "\n" . '  texjobname       => '  . texjobname
  let txt.= "\n" . '  texmode          => '  . texmode
  let txt.= "\n" . ' '
  let txt.= "\n" . '  buildmode        => '  . buildmode
  let txt.= "\n" . ' '
  let txt.= "\n" . '---------- end projs#setbuildvars---------'

  let prf={ 'prf' : '' }
  let log = split(txt,"\n")

  call base#log(log,prf)
    
endfunction

function! projs#git (...)
    call projs#rootcd()
    
endfunction

if 0
  call tree
    called by PrjGrep (plugin/projs_cmds.vim)
endif

function! projs#grep (...)
    let ref=get(a:000,0,{})

    let proj = projs#proj#name()

    let pat = get(ref,'pat','')

    if !strlen(pat)
      let pat = input('Pattern to search for:',
        \ '',
        \ 'custom,projs#complete#hist_grep')
    endif

    let hist = base#varref('projs_hist_grep',[])
    call add(hist,pat)

    let msg_choice_a = [
        \ 'Grep over projects:' ,
        \ 'Choices:',
        \ '',
        \ '  1 - grep over project files - ' . proj,
        \ '  2 - grep over projsdir',
        \ '',
        \ 'Enter grep choice:',
        \ ]

    let choice = input(join(msg_choice_a,"\n"),1)

    call projs#rootcd()

    " grep over this project files
    if choice == 1
      let exts_s = 'tex vim bib'
      let exts_s = input('project file extensions: ',exts_s)

      let exts  = base#qw(exts_s)
      let files = projs#proj#files({ 
        \ "exts" : exts,
        \  })

    " grep over projsdir
    elseif choice == 2

      let tags = projs#select#tags()

      if strlen(tags)
        let files = projs#db#files({ 'tags' : tags })
      else
        let files = [ '*.tex' ]
      endif
    endif

    if !len(files)
      call base#rdwe('projs#grep: no files!')
      return 
    endif

    call base#grep#async({ 
      \ 'files' : files,
      \ 'pat'   : pat 
      \ })


    "call base#grep({ 
        "\ "pat"   : pat   ,
        "\ "files" : files ,
        "\ })
    
endfunction

function! projs#update_qw (s)
  let s = a:s 
  let opts = base#qwsort(s)

  for o in opts
    call projs#update(o)
  endfor

endfunction

function! projs#update (...)
  "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  let msg = ['start']
  let prf = {'plugin' : 'projs', 'func' : 'projs#update'}
  call base#log(msg,prf)
  let l:start=localtime()
  "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

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

"""prjupdate_secnames
    if opt == 'secnames'
        call projs#echo("Updating list of sections",prf)

        call projs#proj#files({ 'rw_f_listfiles' : 1 })

        call projs#proj#secnames()
        call projs#proj#secnamesall()

    elseif opt == 'list'
        call projs#echo("Updating list of projects",prf)

        call projs#listfromfiles()

"""prjupdate_piclist
    elseif opt == 'piclist'
        call projs#echo("Updating list of pictures",prf)

        let pdir = projs#path(['pics',proj])
        let piclist = base#find({ 
            \ "dirs"    : [pdir],
            \ "qw_exts" : 'jpg png eps',
            \ "rmext"   : 1,
            \ "relpath" : 1,
            \ })
        call projs#varset('piclist',piclist)

"""projsupdate_listfiles
    elseif opt == 'listfiles'
        call projs#proj#files({ 'rw_f_listfiles' : 1 })

    elseif opt == 'secnamesbase'
        call projs#echo("Updating list of base sections",prf)

        call projs#varsetfromdat('secnamesbase')

    elseif opt == 'usedpacks'
        call projs#echo("Updating list of used TeX packages",prf)

        call projs#update#usedpacks()

    elseif opt == 'varlist'
        call projs#echo("Updating list of PROJS variables",prf)

        call projs#update#varlist()

    elseif opt == 'datvars'
        call projs#update#datvars()

    elseif opt == 'loaded'
        call projs#echo("Updating list of loaded projects",prf)

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
        call projs#varset('loaded',keys(loaded))

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

