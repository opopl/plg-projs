
"""projs_proj_name

function! projs#proj#name (...)

  if a:0
    let proj = a:1
    call projs#varset('proj',proj)
  else
    let proj = projs#varget('proj','')
  endif
  return proj
endfunction

function! projs#proj#dir_tex4ht (...)
  let qw = get(a:000,0,'')

  let proj = projs#proj#name()
  let root = projs#root()

  let args = [ root, 'data', proj, 'tex4ht' ]
  call extend(args,split(qw,' '))

  let dir = join(args, '/')
  let dir = base#file#win2unix(dir)
  return dir
endfunction

function! projs#proj#dir_pics (...)
  let proj = projs#proj#name()
  let root = projs#root()

  let dir = base#file#catfile([ root, 'pics', proj ])
  return dir
endfunction

function! projs#proj#secname (...)

  if a:0
    let sec = a:1
    call projs#varset('secname',sec)
  else
    let sec = projs#varget('secname','')
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

 elseif act == 'update'
  call projs#proj#files({ 
    \ 'rw_f_listfiles' : 1 ,
    \ })

 elseif act == 'view'
  let extstr = input('File extensions:'."\n",'tex bib vim')
  let exts   = base#qwsort(extstr)

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

function! projs#proj#type (...)
  if a:0
    let t = get(a:000,0,'')
    if strlen(t)
      call projs#varset('projtype',t)
    endif
  else
    let t = projs#varget('projtype','')
  endif
  return t
endfunction

if 0
  let files = projs#proj#files ({ "proj" : proj })
  let files = projs#proj#files ({ "exts" : ["tex"]})
  
  let files = projs#proj#files ()
  
  echo projs#proj#files ({ 'rw_f_listfiles' : 1})
  echo projs#proj#files ()

  call projs#proj#files ({ 'rw_f_listfiles' : 1})
endif

function! projs#proj#files (...)
  let ref = {}
  if a:0 | let ref = a:1 | endif

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let files=[]

  if !strlen(proj) | return files | endif

  let exts = base#qw('tex vim dat pl')
  let exts = get(ref,'exts',exts)

  let prompt = get(ref,'prompt',0)

  let root   = projs#root()
  let dirs   = [ root ]

  let rw_f_listfiles = get(ref,'rw_f_listfiles',0)

  " ======================================
  " start: section (A) reading dat file
  " ======================================

  let f_listfiles = projs#sec#file('_dat_files_') 
  if !rw_f_listfiles
      if filereadable(f_listfiles)
          let content   = readfile(f_listfiles)

          for line in content
            if line =~ '^\s*#'
              continue
            endif

            let ext_f = matchstr(line,'\.\zs\w\+\ze$')
            if base#inlist(ext_f,exts)
                call add(files,line)
            endif
          endfor
          return files
      endif
  endif
  " ======================================
  " end: section (A) reading dat file
  " ======================================
  " start: section (B) locate files through base#find() calls
  " ======================================

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

  if get(ref,'pics',1)
    let picdir      = base#file#catfile([ 'pics',proj ])
    let picdir_full = projs#path([ 'pics',proj ])
    if isdirectory(picdir_full)
      let pref = {
          \   'dirs'       :  [picdir_full]      ,
          \   'relpath'    :  1             ,
          \   'exts'       :  base#qw('jpg png'),
          \   }
      let picfiles = base#find(pref)
      call map(picfiles,'base#file#catfile([ picdir , v:val ])')
      call extend(files,picfiles)
    endif
  endif

  if rw_f_listfiles 
    call base#file#write_lines({ 
      \ 'lines' : files, 
      \ 'file'  : f_listfiles, 
      \})
  endif

  return files
  
endfunction

" Calculate available section names for
"   the current project

" projs#proj#secnames ()
" projs#proj#secnames (proj)

function! projs#proj#secnames (...)
  let proj = projs#proj#name()
  let proj = get(a:000,0,proj)

  let secnames = projs#db#secnames()
  let secnames = sort(secnames)

  call projs#varset('secnames',secnames)
  call projs#proj#secnamesall()

  return secnames
  
endfunction

function! projs#proj#secnamesall (...)

  let sall = projs#varget('secnames',[])
  call extend(sall,projs#varget('secnamesbase',[]))
  let sall = sort(base#uniq(sall))

  call projs#varset('secnamesall',sall)

  return sall

endfunction
"
"""projs_proj_listfiles

" list existing files belonging to the project
"   being selected
"
function! projs#proj#listfiles (...)
  let proj = projs#proj#name()

  let extstr = 'tex bib vim'
  let extstr = input('File extensions:'."\n", extstr)
  let exts = base#qwsort(extstr)

  let pics = input('Include pics? 1/0:',1)

  let pfiles = projs#proj#files({ 
    \ "proj" : proj, 
    \ 'exts' : exts, 
    \ 'pics' : pics,
    \  }) 

  let lines = []
  call extend(lines,[ 'project files: '])
  call extend(lines,base#map#add_tabs(pfiles) )
  call base#buf#open_split({ 'lines' : lines })
  
endfunction

function! projs#proj#listsecnames (...)
  let proj = projs#proj#name()
  if a:0
    let proj = a:1
  endif

  let secnames     = projs#proj#secnames(proj)
  let secnamesall  = base#varget('projs_secnamesall',[])
  let secnamesbase = base#varget('projs_secnamesbase',[])

  let lines = []

  let bufsecs = []
  let data_h = []
  let headers = [ 'buf' , 'sec' ]
  for sec in secnamesall
    let bnr = projs#sec#bufnr(sec)
    if ! len(bnr)
      continue
    endif
    call add(data_h,{ 'buf' : bnr, 'sec' : sec })
    call add(bufsecs,sec)
  endfor
  let lines_bufsecs = pymy#data#tabulate({
    \ 'data_h'  : data_h,
    \ 'headers' : headers,
    \ })
  call add(lines,'(buf) projs_secnames:')
  call extend(lines,base#mapsub(lines_bufsecs,'^','\t','g'))

  call add(lines,'projs_secnames:')
  call extend(lines,base#mapsub(secnames,'^','\t','g'))

  call add(lines,'projs_secnamesall:')
  call extend(lines,base#mapsub(secnamesall,'^','\t','g'))

  call add(lines,'projs_secnamesbase:')
  call extend(lines,base#mapsub(secnamesbase,'^','\t','g'))

  let cmds_pre = [ 
    \ 'resize 99',
    \ "vnoremap <silent><buffer> v :'<,'>call projs#sec_vis#open()<CR>",
    \ ]

  for sec in bufsecs
    let cmds = []

    let hl = 'MoreMsg'
    call add(cmds, printf('call matchadd("%s","\\s\\+%s\\s\\+")',hl,sec))
    call add(cmds, printf('call matchadd("%s","\\s\\+%s$")',hl,sec))

    call extend(cmds_pre,cmds)
  endfor
  for tf in tagfiles()
    call extend(cmds_pre,[ 'setlocal tags+='.escape(tf,' ') ])
  endfor

  call base#buf#open_split({ 
    \ 'lines'    : lines, 
    \ 'cmds_pre' : cmds_pre,
    \ 'stl_add'  : [ 'V[ v - open section ]' ]
    \ })
  
endfunction

function! projs#proj#db_remove(proj)
 let proj = a:proj

  let q = 'DELETE FROM projs WHERE proj = ?'
  let ref = {
      \ 'query'  : q,
      \ 'params' : [ proj ],
      \ }
  call projs#db#query(ref)
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

"used by: PrjRemove

function! projs#proj#remove(...)

 let proj   = get(a:000,0,'')

 if !len(proj)
   let proj = projs#selectproject()
 endif

 let ok     = 0
 let prefix = '(projs#proj#remove) '

 call base#echoprefix(prefix)

 if ! projs#ex(proj)
  call base#warn({ 
    \ 'text'   : 'Input project does not exist:  ' . proj,
      \   })
  return 1
 endif

 let projs = projs#list()

 """ remove proj from projs
 call filter(projs,"v:val != proj") 

 call projs#proj#removefromdat(proj)
 call projs#proj#db_remove(proj)

 let pfiles = projs#proj#files({ "proj" : proj })
 call map(pfiles,'projs#path([ v:val ])')

 for file in pfiles
   if filereadable(file)
    echo 'Removing file: ' . file

    if has('unix')
      let cmds=[ 
        \ "git reset HEAD " . file . ' || echo $?',
        \ "git checkout -- " . file . ' || echo $?',
          \ "git rm " . file . ' -f || rm -f ' . file,
          \ ]
    else
      let cmds=[ 
        \ "git reset HEAD " . file . '',
        \ "git checkout -- " . file . '',
          \ "git rm " . file . ' -f',
          \ "del " . file,
          \ ]

    endif

      call base#sys({
      \ "cmds"   : cmds   ,
      \ "prompt" : 0      ,
      \ "skip_errors" : 1 ,
      \ })
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

  if base#inlist(cmd,base#qw('rm add'))
    for f in files
      let fcmd= 'git '.cmd. ' '.f

      let refsys={ 
              \ "cmds"         : [fcmd],
              \ "split_output" : 0,
              \   }
      call base#sys(refsys)

    endfor
  endif

endfunction

function! projs#proj#git_add ()
  let texfiles = projs#varget('texfiles',[])

  let newopts = projs#varget('PrjNew_opts',{})

  let git_add = get(newopts,'git_add',0)
  let git_add = input('Add each new file to git? (1/0): ',git_add)

  if !git_add | return | endif
  
  for file in values(texfiles)
    if filereadable(file)
      if ! base#sys("git add " . file )
        return 0
      endif
    endif
  endfor

        
endfunction

 
