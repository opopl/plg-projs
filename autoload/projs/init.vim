
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
    let rootid = get(a:000,0,'')

    let root   = projs#varget('root',base#envvar('PROJSDIR'))

    if !len(root)
      let rootid = projs#varget('rootid','texdocs')
      call projs#varset('rootid',rootid)
    endif

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
