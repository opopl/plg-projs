
" Used: 
"   in projs#init()
"
" Usage:
"   call projs#init#root ()
"   call projs#init#root (rootid)
" Purpose:
"   set the value of 'root' from:
"     -  rootid, if given as first argument
"     -  PROJSDIR env variable, if called with no arguments
" Returns:
"   return [root,rootid]

function! projs#init#root (...)
    let rootid = projs#varget('rootid','')
    let rootid = get(a:000,0,rootid)

		let root = ''
    if len(rootid)
      let dir     = base#path(rootid)

      if !strlen(dir)
        let dir = rootid
      endif

      call base#mkdir(dir)
      let root = dir
    endif

    if isdirectory(root)
        call projs#varset('rootid',rootid)
        call projs#varset('root',root)
    endif

    call base#pathset({ 'projs' : root })

    let msg = ['rootid = ' . rootid, 'root = ' . root ]
    let prf = {'plugin' : 'projs', 'func' : 'projs#init#root'}
    call base#log(msg,prf)

    return [root,rootid]
  
endfunction

function! projs#init#templates (...)
  "xxxxxxxxxxxxxxxxxxxxxxxx
  let msg = ['start']
  let prf = {'plugin' : 'projs', 'func' : 'projs#init#templates'}
  let l:start = localtime()
  call base#log(msg,prf)
  "xxxxxxxxxxxxxxxxxxxxxxxx

  let tdir=base#qw#catpath('plg','projs templates')

  if !isdirectory(tdir)
    return
  endif

  let t={}
  let template_types=projs#varget('template_types',[])

  for k in template_types 
    let t[k] = projs#varget('templates_'.k,{})
    let te   = t[k]

    let d    = base#file#catfile([ tdir, k ])

    if !isdirectory(tdir) | continue | endif

    let ext  = k
    let exts = base#qw(ext)

    let found = base#find({ 
        \ "dirs"    : [d],
        \ "exts"    : exts,
        \ "cwd"     : 0,
        \ "relpath" : 1,
        \ "rmext"   : 1,
        \ })
    for f in found
      let p = base#file#catfile([ d, f .'.'.ext ])
      if !filereadable(p)
        call projs#warn('File NOT exist:'."\n\t".p)
      endif
      let lines=readfile(p)
      let te[f]=lines
    endfor

    call projs#varset('templates_'.k,te)
  endfor
  call projs#update('varlist')


  "xxxxxxxxxxxxxxxxxxxxxxxx
  let l:elapsed = localtime()-l:start
  let msg = ['end, elapsed = ' . l:elapsed]
  let prf = {'plugin' : 'projs', 'func' : 'projs#init#templates'}
  call base#log(msg,prf)
  "xxxxxxxxxxxxxxxxxxxxxxxx

endfunction

function! projs#init#var (...)
  let varname = get(a:000,0,'')

  if varname == 'pdffin'
    
    let pdffin = exists('$PDFOUT') ? $PDFOUT : base#qw#catfile('C: out pdf')
    
    call projs#varset('pdffin',pdffin)
    call base#mkdir(pdffin)

  elseif varname == 'pdfout'
    let pdfout = projs#path([ 'pdf_built' ])

    call projs#varset('pdfout',pdfout)
    call base#mkdir(pdfout)

  elseif varname == 'prjmake_opt'
    call projs#varset('prjmake_opt','latexmk')

  elseif varname == 'rootbuilddir'
    let rootbuilddir = projs#path([ 'builds' ])
    call projs#varset('rootbuilddir',rootbuilddir)
    call base#mkdir(rootbuilddir)

  elseif varname == 'exe_latex'
    call projs#varset('exe_latex','pdflatex')

  elseif varname == 'projsdirs'
    let projsdirs = projs#varget('projsdirs')
    call projs#varset('projsdirslist',projsdirs)

  endif

endfunction

if 0
  projs#init#cmds

  Purpose:
    initialize PROJS plugin commands
  Usage:
    call projs#init#cmds ()
  Returns:
    Nothing 
  Call tree:
      
    called by:
    uses:
      projs#complete
      
endif

function! projs#init#cmds (...)

"""PV
  command! -nargs=* -complete=custom,projs#complete            PV
    \ call projs#viewproj(<f-args>) 
  
"""PN
  command! -nargs=* -complete=custom,projs#complete            PN
    \ call projs#new(<f-args>) 
  
  "command! -nargs=* -complete=custom,projs#complete#projsdirslist
  "
"""ProjsInit
  command! -nargs=* -complete=custom,projs#complete#projsdirs ProjsInit
    \ call projs#init(<f-args>)
  
"""ProjsVarEcho
  command! -nargs=* -complete=custom,projs#complete#varlist    ProjsVarEcho 
    \ call projs#varecho(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#gitcmds    ProjsGit
    \ call projs#git(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#projsload  ProjsLoad
    \ call projs#load(<f-args>)
  
"""PrjView
  command! -nargs=* -complete=custom,projs#complete            PrjView
    \ call projs#viewproj(<f-args>) 
  
"""PrjNew
  command! -nargs=* -complete=custom,projs#complete            PrjNew
    \ call projs#new(<f-args>) 
  
"""PrjPdfView
  command! -nargs=* -complete=custom,projs#complete            PrjPdfView
    \ call projs#pdf#view(<f-args>) 
  
  command! -nargs=* -complete=custom,projs#complete#prjmake    PrjMake
    \ call projs#prjmake(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#prjmake    PrjMakePrompt
    \ call projs#prjmakeprompt(<f-args>)
  
"""PrjRename
  command! -nargs=* -complete=custom,projs#complete            PrjRename
    \ call projs#renameproject(<f-args>)
  
"""PrjRemove
  command! -nargs=* -complete=custom,projs#complete            PrjRemove
    \ call projs#proj#remove(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#secnames   PrjJoin
    \ call projs#filejoinlines({ 'write_jfile' : 1 })
  
  command! -nargs=* -complete=custom,projs#complete#grep       PrjGrep
    \ call projs#grep(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#update     PrjUpdate
    \ call projs#update(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#varlist    PrjVarEcho
    \ call projs#varecho(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#varlist    PrjVarSet
    \ call projs#cmd#varset(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#secnamesall PrjSecNew
    \ call projs#sec#new(<f-args>,{ "view" : 1 })
  
  command! -nargs=* -complete=custom,projs#complete#secnames PrjSecRename
    \ call projs#sec#rename(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#secnames PrjSecDelete
    \ call projs#sec#delete_prompt(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#defs     PrjDefShow
    \ call projs#def#show(<f-args>) 
  
  command! -nargs=*             PrjDefNew
    \ call projs#def#new(<f-args>) 
  
  command! -nargs=* -complete=custom,projs#complete#prjfiles PrjFiles
    \ call projs#proj#filesact(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete          PrjListSecs 
    \ call projs#proj#listsecnames(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#prjgit   PrjGit 
    \ call projs#proj#git(<f-args>)
  
  "command! -nargs=* -complete=custom,projs#complete
    "\ PrjMake call projs#prjmake(<f-args>)
  
  "command! -nargs=* -complete=custom,projs#complete PrjBuildCleanup 
    "\ call projs#build#cleanup(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#prjbuild PrjBuild
    \ call projs#build#action(<f-args>)
  
"""PrjAct
if 0
	BaseDatView projs_opts_PrjAct
endif
  command! -nargs=* -complete=custom,projs#complete#prjact PrjAct
    \ call projs#action(<f-args>)
  
  "command! -nargs=* -complete=custom,projs#complete#prjtab PrjTab
    "\ call projs#tables(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#prjgui PrjGui
    \ call projs#gui(<f-args>)
  
"""PrjBuf
  command! -nargs=* -complete=custom,projs#complete#prjbuf PrjBuf
    \ call projs#buf_cmd(<f-args>)
  
"""PrjVisual
if 0
	BaseDatView projs_opts_PrjVisual
endif
  command! -nargs=* -range -complete=custom,projs#complete#prjvisual
    \ PrjVisual call projs#visual(<line1>,<line2>,<f-args>)
  
"""PrjDB
  command! -nargs=* -complete=custom,projs#complete#prjdb PrjDB
    \ call projs#db#action(<f-args>)
  
  command! -nargs=* -complete=custom,projs#complete#htlatex PrjHtlatex
    \ call projs#htlatex(<f-args>)
  
"""PrjInsert
  command! -nargs=* -complete=custom,projs#complete#prjinsert PrjInsert
    \ call projs#insert(<f-args>)
  
"""PrjSwitch
  command! -nargs=* -complete=custom,projs#complete#switch PrjSwitch
    \ call projs#switch(<f-args>)
  
"""VSECBASE
  command! -nargs=* -complete=custom,projs#complete#secnamesbase VSECBASE
      \ call projs#sec#open(<f-args>) 
  
"""VSEC
  command! -nargs=* -complete=custom,projs#complete#secnames     VSEC
      \ call projs#sec#open_load_buf(<f-args>) 

endfunction


"Call tree
" Called by
"   projs#init

function! projs#init#au (...)
  let root   = projs#root()
  let root_u = base#file#win2unix(root)

  augroup plg_projs
    au!
    autocmd BufWinEnter,BufRead,BufNewFile *.cld setf tex
    exe 'autocmd BufWinEnter,BufRead,BufNewFile '. root_u  .'/**/*.csv  call projs#au#file_onload_csv() '
    exe 'autocmd BufWinEnter,BufRead,BufNewFile '. root_u  .'/**/*.vim  call projs#au#file_onload_vim() '

    exe 'autocmd BufWinEnter,BufRead,BufNewFile '. root_u  .'/makefile  call projs#au#file_onload_make() '
    exe 'autocmd BufWinEnter,BufRead,BufNewFile '. root_u  .'/*.mk      call projs#au#file_onload_make() '
    autocmd BufWinEnter,BufRead,BufNewFile *.bat call projs#au#file_onload_bat()
  augroup end
endfunction
