
"---------------------------------
"
" Section-related functions:
"
"   projs#sec#new(sec)
"
"   projs#sec#rename(new, old)
"
"   projs#sec#open(sec)
"   projs#sec#append({ sec : sec, lines : lines })
"
"---------------------------------
"
function! projs#sec#append (...)
  let ref = get(a:000,0,{})

  let sec   = get(ref,'sec','')
  let lines = get(ref,'lines',[])
  let text  = get(ref,'text','')
  
  call extend(lines, split(text,"\n") )

  let file = projs#sec#file(sec)

  let r = {
      \ 'lines' : lines,
      \ 'file'  : file,
      \ 'mode'  : 'append',
      \ }
  call base#file#write_lines(r)

endf

"projs#sec#rename( new,old ) 

function! projs#sec#rename (...)
  let new = get(a:000,0,'')

  let old = projs#proj#secname()
  let old = get(a:000,1,old)

  while !strlen(new)
		let msg = printf('[ sec=%s ] New section name: ',old)
    let new = input(msg,'','custom,projs#complete#secnames')
  endw

  let oldf = projs#sec#file(old)
  let newf = projs#sec#file(new)

  let oldf_base = projs#sec#file_base(old)
  let newf_base = projs#sec#file_base(new)

	let msg_a = [
		\	" ",	
		\	"Old: " . oldf,	
		\	"New: " . oldf,	
		\	" ",	
		\	"This will rename sections, old => new",	
		\	" ",	
		\	"Are you sure? (1/0): ",	
		\	]
	let msg = join(msg_a,"\n")
	let do_rename = base#input_we(msg,0,{ })
	if !do_rename
		redraw!
		echohl MoreMsg
		echo 'Rename aborted'
		echohl None
		return 
	endif

  call rename(oldf,newf)

  let lines = readfile(newf)

  let nlines = []
  let pats = {}
  call extend(pats,{ '^\(%%file\s\+\)\(\w\+\)\s*$' : '\1'.new  })
  call extend(pats,{ '^\(\\label{sec:\)'.old.'\(}\s*\)$' : '\1'.new.'\2' })
  
  for line in lines
    for [pat,subpat] in items(pats)
      if line =~ pat
        let line = substitute(line,pat,subpat,'g')
      endif
    endfor

    call add(nlines,line)
  endfor

  call writefile(nlines,newf)

  let pfiles = projs#proj#files()
  let ex = {}
  for pfile in pfiles
    call extend(ex,{ pfile : 1 })
  endfor
  call extend(ex,{ newf_base : 1, oldf_base : 0 })

  let pfiles=[]
  for [file,infile] in items(ex)
    if infile
      call add(pfiles,file)
    endif
  endfor

  let f_listfiles = projs#sec#file('_dat_files_') 

  call base#file#write_lines({ 
      \ 'lines' : pfiles,
      \ 'file'  : f_listfiles,
      \})

  call projs#proj#secnames()
  call base#fileopen({ 'files' : [newf]})
  
endfunction

"Usage:
"  call projs#sec#delete (sec)
"
"Call tree:
"  Calls:
"    projs#proj#secname
"    projs#sec#file

function! projs#sec#delete (...)

  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  let ok = 1
  let ok = ok && projs#sec#delete_from_vcs(sec)
  let ok = ok && projs#sec#delete_from_db(sec)
  let ok = ok && projs#sec#delete_from_fs(sec)

  if ok
    call projs#echo('Section has been deleted: ' . sec)
  endif

endfunction

function! projs#sec#delete_from_vcs (sec,...)
  let sec = a:sec 

  let secfile   = projs#sec#file(sec)

  if filereadable(secfile)
    let dirname = fnamemodify(secfile,':p:h')
    let bname   = fnamemodify(secfile,':p:t')
    call base#cd(dirname)
    let cmd = 'git rm ' . bname . ' --cached '
    let ok = base#sys({ 
      \ "cmds"         : [cmd],
      \ "split_output" : 0,
      \ "skip_errors"  : 1,
      \ })
  else
    call projs#warn('Section file does not exist for: '.sec)
    return
  endif

endfunction


function! projs#sec#delete_from_fs (sec,...)
  let sec = a:sec 

  let secfile   = projs#sec#file(sec)

  let ok = base#file#delete({ 'file' : secfile })
  return ok
endfunction

function! projs#sec#delete_from_db (sec,...)
  let sec = a:sec 

  let ref = get(a:000,0,{})

  let dbfile  = projs#db#file()

  let proj = projs#proj#name()

  let r = {
      \  'q' : 'DELETE FROM projs WHERE proj = ? AND sec = ?',
      \  'p' : [ proj, sec ],
      \  }
  call pymy#sqlite#query(r)
  let ok = 1

  return ok
endfunction

function! projs#sec#onload (sec)
  let sec = a:sec

  let prf = { 'prf' : 'projs#sec#onload' }
  call base#log([
    \ 'sec => ' . sec,
    \ ],prf)
  call projs#sec#add(sec)

  return
endfunction

function! projs#sec#parent ()
  let parent = projs#varget('parent_sec','')
  return parent
endfunction

function! projs#sec#file (...)
  let proj = projs#proj#name()

  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  let secfile = projs#path( projs#sec#file_base_a(sec) )
  return secfile
endf

function! projs#sec#filecheck (...)
    let sec = a:1
    let sfile = projs#sec#file(sec)

    if !filereadable(sfile)
        call projs#sec#new(sec)
    endif

    return 1
endf


function! projs#sec#file_base (...)
  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  let sfile_a = projs#sec#file_base_a(sec)

  let sfile = base#file#catfile(sfile_a)
  return sfile
endf

function! projs#sec#file_base_a (...)
    
    let sec = projs#proj#secname()
    let sec = get(a:000,0,sec)

    let dot = '.'

    let proj = projs#proj#name()
    let sfile_a = []

    let runext = (has('win32')) ? 'bat' : 'sh' 

    if sec == '_main_'
        let sfile_a = [ proj.'.tex']

    elseif sec == '_vim_'
        let sfile_a = [ proj.'.vim']

    elseif sec == '_pl_'
        let sfile_a = [ proj.'.pl']

    elseif sec == '_osecs_'
        let sfile_a = [ proj.'.secorder.i.dat']

    elseif sec == '_dat_'
        let sfile_a = [ proj . '.secs.i.dat' ]

    elseif sec == '_dat_defs_'
      let sfile_a = [ proj . '.defs.i.dat' ]

    elseif sec == '_dat_files_'
      let sfile_a = [ proj . '.files.i.dat' ]

    elseif sec == '_dat_files_ext_'
      let sfile_a = [ proj . '.files_ext.i.dat' ]

    elseif sec == '_dat_citn_'
        let sfile_a = [ proj.'.citn.i.dat']

    elseif sec == '_bib_'
        let sfile_a = [ proj.'.refs.bib']

    elseif sec == '_xml_'
        let sfile_a = [ proj.'.xml' ]

    elseif sec == '_join_'
        let sfile_a = [ 'joins', proj . '.tex' ]

    elseif sec == '_build_pdflatex_'
        let sfile_a = [ 'b_' . proj . '_pdflatex.'.runext ]

    elseif sec == '_build_perltex_'
        let sfile_a = [ 'b_' . proj . '_perltex.'.runext ]

    elseif sec == '_build_htlatex_'
        let sfile_a = [ 'b_' . proj . '_htlatex.'.runext ]

    elseif sec == '_main_htlatex_'
        let sfile_a = [ proj . '.main_htlatex.tex' ]

    else
        let sfile_a = [proj.dot.sec.'.tex']

    endif

    return sfile_a
    
endfunction

"call tree
"  called by
"    projs#sec#add

function! projs#sec#add_to_secnames (sec)
  let sec = a:sec 

  if ! projs#sec#exists(sec)
    let secnames    = base#varref('projs_secnames',[])
    let secnamesall = base#varref('projs_secnamesall',[])

    call add(secnames,sec)
    call add(secnamesall,sec)

    let secnamesall = base#uniq(secnamesall)
    let secnames    = base#uniq(secnames)
  endif
endfunction

function! projs#sec#add_to_dat (sec)
  let sec = a:sec 

  let sfile = projs#sec#file(sec)
  let sfile = fnamemodify(sfile,':p:t')

  let pfiles =  projs#proj#files()
  if !base#inlist(sfile, pfiles)
    call add(pfiles,sfile)
  
    let f_listfiles = projs#sec#file('_dat_files_')
    call base#file#write_lines({ 
      \ 'lines' : pfiles, 
      \ 'file'  : f_listfiles, 
      \})
  endif
endfunction



function! projs#sec#add_to_db (sec,...)
  let ref = get(a:000,0,{})

  let tags   = get(ref,'tags','')
  let author = get(ref,'author','')

  let sec = a:sec 

  let dbfile  = projs#db#file()

  let sfile = projs#sec#file(sec)
  let sfile = fnamemodify(sfile,':p:t')

  let proj = projs#proj#name()
  
  let t = "projs"
  let h = {
    \ "proj"   : proj,
    \ "sec"    : sec,
    \ "file"   : sfile,
    \ "root"   : projs#root(),
    \ "rootid" : projs#rootid(),
    \ "tags"   : tags,
    \ "author" : author,
    \ }
  
  let ref = {
    \ "dbfile" : dbfile,
    \ "i"      : "INSERT OR IGNORE",
    \ "t"      : t,
    \ "h"      : h,
    \ }
    
  call pymy#sqlite#insert_hash(ref)

endfunction

" projs#sec#add
"
" Purpose:
"   - add sec to the list of sections in dat-file: _dat_files_
"   - add sec to var: projs_secnames
"   - add sec to var: projs_secnamesall
"   - add sec to db
"   
" Usage:
"   call projs#sec#add (sec)
" Returns:
"   
"
" Call tree:
"   calls:
"     projs#proj#name
"     projs#sec#file
"     projs#proj#files
"     base#file#write_lines
"     projs#sec#exists
"     projs#db#file
"   called by:
"     projs#sec#new

function! projs#sec#add (sec)
  let sec   = a:sec

  call projs#sec#add_to_secnames(sec)
  call projs#sec#add_to_dat(sec)
  call projs#sec#add_to_db(sec)

  return 1
endfunction

function! projs#sec#exists (...)
  let sec = get(a:000,0,'')

  let sec_file = projs#sec#file(sec)

  let ok = 1
  let ok = ok && filereadable(sec_file)

  return ok

endfunction

" projs#sec#new(sec)
" projs#sec#new(sec,{ "git_add" : 1 })
" projs#sec#new(sec,{ "view" : 1 })
" projs#sec#new(sec,{ "prompt" : 0 })
" projs#sec#new(sec,{ "rewrite" : 1 })
"
" end of function: end_projs_sec_new

function! projs#sec#new(sec,...)
    let sec        = a:sec

    let proj       = projs#proj#name()
    let parent_sec = projs#sec#parent()

    let ref = { 
        \   "git_add" : 0, 
        \   "view"    : 0, 
        \   "prompt"  : 0, 
        \   "seccmd"  : '', 
        \   "lines"   : [], 
        \   }

    if a:0 
        let refadd = get(a:000,0,{})
        call extend(ref, refadd)
    endif

    let parent_sec = get(ref,'parent_sec',parent_sec)

    let rw = get(ref,'rewrite',0)
    if projs#sec#exists(sec) && !rw
        return
    endif

    let o = base#varget('projs_opts_PrjSecNew',{})

    let prompt = get(o,'prompt',1)
    let prompt = get(ref,'prompt',prompt)

    call projs#echo("Creating file:\n\t" . sec )

    let lines = []
    call extend(lines, get(ref, 'add_lines_before', [] ) )

    let sec_file = projs#sec#file(sec)

    let lines = []

    let rh = { 
      \ 'sec'        : sec,
      \ 'parent_sec' : parent_sec,
      \ }

    if fnamemodify(sec_file,':p:e') == 'tex'
      let keymap = projs#select#keymap({ 'prompt' : prompt })
      if strlen(keymap)
        call extend(rh,{ 'keymap' : keymap })
      endif
    endif
    call extend(lines, projs#sec#header(rh) )

    let projtype = projs#varget('projtype','regular')
    let sub = 'projs#newseclines#'.projtype.'#'.sec
    try
      let r = {
          \ 'proj' : proj,
          \ }
      exe printf('call extend(lines,%s(r))',sub)
    catch 
      call projs#warn('Problems while executing:'."\n\t".sub)
    endtry

    let inref = { 'prompt' : prompt }

    if sec =~ '^fig_'
      call extend(lines,projs#newseclines#fig_num(sec))

"""newsec__vim_
    elseif sec == '_vim_'
      let r = {
          \ 'proj'     : proj,
          \ 'projtype' : projtype,
          \ }
      call extend(lines,projs#newseclines#_vim_(r))

    elseif base#inlist(sec,base#qw('_build_perltex_ _build_pdflatex_'))
      let r = {
          \ 'proj' : proj,
          \ 'sec'  : sec,
          \ }
      call extend(lines, projs#newseclines#_build_tex_(r))

    else
        if prompt 
          call extend(lines, projs#sec#lines_prompt(r))
        else
          let r_sc = copy(r)
          call extend(r_sc,{ 'seccmd' : get(ref,'seccmd','section') })
          call extend(lines, projs#sec#lines_seccmd(r_sc))
        endif
 
    endif

    call extend(lines,get(ref,'add_lines_after',[]))

    call writefile(lines,sec_file)
    call projs#sec#add(sec)

    if get(ref,'git_add')
      let dir = fnamemodify(sec_file,':p:h')
      let bname = fnamemodify(sec_file,':p:t')
      call base#sys("git add " . bname)
    endif

    if get(ref,'view')
        exe 'split ' . sec_file
    endif
    
    return 1
endfunction
"""end_projs_sec_new

function! projs#sec#open (...)
 let proj = projs#proj#name()

 let parent_sec = projs#proj#secname()

 if a:0 == 1
    let sec=a:1
 else
    let sec=projs#select#sec()
 endif

 if !projs#sec#exists(sec)
    let cnt = input('Section does not exist, continue? (1/0):',1)
    if !cnt | return | endif

    call projs#sec#add(sec)
 endif

  call projs#varset("secname",sec)

  let vfile             = ''
  let vfiles            = []

  if projs#varget('secdirexists',0)
    let vfile = projs#path([ proj, sec . '.tex' ])
  else
    let vfile = projs#sec#file(sec) 
  endif

  if sec == '_main_'
        for ext in projs#varget('extensions_tex',[])
            let vfile = projs#path([ proj . '.' . ext ])
                if filereadable(vfile)
                    call add(vfiles, vfile)
                endif
        endfor

  elseif sec == '_dat_'
    call projs#gensecdat()

    return
  elseif sec == '_osecs_'
    call projs#opensecorder()

    return

  elseif sec == '_join_'

    call projs#filejoinlines()

  elseif sec == '_pl_all_'
    call extend(vfiles,base#splitglob('projs',proj . '.*.pl'))
    call extend(vfiles,base#splitglob('projs',proj . '.pl'))
    let vfile=''

  else

    let vfile = projs#sec#file(sec)
  endif

  if strlen(vfile) 
    call add(vfiles,vfile)
  endif

  call projs#varset('curfile',vfile)

  let vfiles = base#uniq(vfiles)

  call projs#varset("parent_sec",parent_sec)

  for vfile in vfiles
    if !filereadable(vfile)
        call projs#sec#new(sec)
    endif
    call base#fileopen(vfile) 
  endfor


  call base#stl#set('projs')
  "KEYMAP russian-jcukenwin
  KEYMAP ukrainian-jcuken

  return 
endf


function! projs#sec#header (...)
  let ref=get(a:000,0,{})

  let sec        = get(ref,'sec','')
  let keymap     = get(ref,'keymap','')
  let parent_sec = get(ref,'parent_sec','')
  
  let header = []

  if strlen(keymap)
    call add(header,'% vim: keymap=' . keymap )
  endif

  call extend(header,[ '%%file ' . sec])
  call extend(header,[ '%%parent ' . parent_sec ])

  return header
endf

function! projs#sec#lines_seccmd (...)
  let ref = get(a:000,0,{})

  let sec    = get(ref,'sec','')
  let seccmd = get(ref,'seccmd','')

  let lines = []

  if strlen(seccmd)
    let title = sec
    let label = 'sec:'.sec

    call add(lines,'\' . seccmd . '{'.title.'}')
    call add(lines,'\label{'.label.'}')
    call add(lines,' ')
  endif

  return lines
endf

function! projs#sec#lines_prompt (...)
  let ref = get(a:000,0,{})

  let sec = get(ref,'sec','')

  let cnt = input('Continue adding? (1/0):',1)

  let lines = []
  
  if cnt
    let addsec = input('Add sectioning? (1/0):',1)
    if addsec
      let seccmd = input('Sectioning command: ','section','custom,tex#complete#seccmds')
      
      let title = input('Title: ',sec)
      let label = input('Label: ','sec:' . sec)
      
      call add(lines,'\' . seccmd . '{'.title.'}')
      call add(lines,'\label{'.label.'}')
      call add(lines,' ')
    endif
  endif

  return lines
endf
