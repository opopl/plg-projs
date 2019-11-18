
"---------------------------------
"
"	Section-related functions:
"
"		projs#sec#new(sec)
"
"		projs#sec#rename(new, old)
"
"		projs#sec#open(sec)
"		projs#sec#append({ sec : sec, lines : lines })
"
"---------------------------------
"
function! projs#sec#append (...)
	let ref = get(a:000,0,{})

	let sec   = get(ref,'sec','')
	let lines = get(ref,'lines',[])

	let file = projs#sec#file(sec)

	let r = {
			\	'lines' : lines,
			\	'file' : file,
			\	'mode' : 'append',
			\	}
	call base#file#write_lines(r)

endf

"projs#sec#rename( new,old ) 

function! projs#sec#rename (...)
	let new = get(a:000,0,'')

	let old = projs#proj#secname()
	let old = get(a:000,1,old)

	if !strlen(new)
		let new = input('[sec='.old.' ] New section name: ','','custom,projs#complete#secnames')
	endif

	let oldf = projs#sec#file(old)
	let newf = projs#sec#file(new)

	let oldf_base = projs#sec#file_base(old)
	let newf_base = projs#sec#file_base(new)

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
			\	'lines' : pfiles,
			\	'file'  : f_listfiles,
			\})

	call projs#proj#secnames()
	call base#fileopen({ 'files' : [newf]})
	
endfunction

function! projs#sec#delete (...)

	let sec = projs#proj#secname()
	let sec = get(a:000,0,sec)

	let secfile   = projs#sec#file(sec)
	let secfile_u = base#file#win2unix(secfile)

	if filereadable(secfile)
		let cmd = 'git rm ' . secfile_u . ' --cached '
		let ok = base#sys({ 
			\	"cmds"         : [cmd],
			\	"split_output" : 0,
			\	"skip_errors"  : 1,
			\	})
	else
		call projs#warn('Section file does not exist for: '.sec)
		return
	endif

	let ok = base#file#delete({ 'file' : secfile })

	if ok
		call projs#echo('Section has been deleted: ' . sec)
	endif

endfunction

function! projs#sec#onload (sec)
	let sec = a:sec

	let prf = { 'prf' : 'projs#sec#onload' }
	call base#log([
		\	'sec => ' . sec,
		\	],prf)
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


"	projs#sec#add
"
"	Purpose:
"		
"	Usage:
"		call projs#sec#add (sec)
"	Returns:
"		
"
"	Call tree:
"		calls:
"			projs#proj#name
"			projs#sec#file
"			projs#proj#files
"			base#file#write_lines
"			projs#sec#exists
"			projs#db#file
"		called by:
"			

function! projs#sec#add (sec)
	let sec   = a:sec

	let proj = projs#proj#name()

	let sfile = projs#sec#file(sec)
	let sfile = fnamemodify(sfile,':p:t')

	let pfiles =	projs#proj#files()
	if !base#inlist(sfile,pfiles)
		call add(pfiles,sfile)
	
		let f_listfiles = projs#sec#file('_dat_files_')
		call base#file#write_lines({ 
			\	'lines' : pfiles, 
			\	'file'  : f_listfiles, 
			\})
	endif

	if ! projs#sec#exists(sec)
		let secnames    = base#varget('projs_secnames',[])
		let secnamesall = base#varget('projs_secnamesall',[])

		call add(secnames,sec)
		call add(secnamesall,sec)

		let secnamesall = base#uniq(secnamesall)
		let secnames    = base#uniq(secnames)
	endif

	let dbfile  = projs#db#file()
	
	let t = "projs"
	let h = {
		\	"proj"   : proj,
		\	"sec"    : sec,
		\	"file"   : sfile,
		\	"root"   : projs#root(),
		\	"rootid" : projs#rootid(),
		\	"tags"   : "",
		\	"author" : "",
		\	}
	
	let ref = {
		\ "dbfile" : dbfile,
		\ "i"      : "INSERT OR IGNORE",
		\ "t"      : t,
		\ "h"      : h,
		\ }
		
	call pymy#sqlite#insert_hash(ref)

endfunction

function! projs#sec#exists (...)
	let sec = get(a:000,0,'')

	let secnamesall = projs#proj#secnamesall ()

	return base#inlist(sec,secnamesall)

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
        \   "prompt"  : 1, 
        \   "seccmd"  : '', 
        \   "lines"   : [], 
        \   }

    call extend(ref,{ "prompt" : 0 })

    if a:0 
        let refadd = get(a:000,0,{})
        call extend(ref, refadd)
    endif

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

    let file = projs#sec#file(sec)

    let secs = base#qw("preamble body")

    let lines = []

		let keymap = projs#select#keymap()

		let rh = { 
			\	'sec'        : sec,
			\	'keymap'     : keymap,
			\	'parent_sec' : parent_sec ,
	 		\	}
    call extend(lines, projs#sec#header(rh) )

    let projtype = projs#varget('projtype','regular')
    let sub = 'projs#newseclines#'.projtype.'#'.sec
    try
			let r = {
					\	'proj' : proj,
					\	}
      exe 'let lines='.sub.'(r)'
    catch 
      call projs#warn('Problems while executing:'."\n\t".sub)
    endtry

    let inref = { 'prompt' : prompt }

"""newsec__main__
    if sec == '_main_'

      let file = projs#path([ proj.'.tex'])

    elseif sec =~ '^fig_'
			call extend(lines,projs#newseclines#fig_num(sec))

"""newsec__vim_
    elseif sec == '_vim_'
			let r = {
					\	'proj'     : proj,
					\	'projtype' : projtype,
					\	}
			call extend(lines,projs#newseclines#_vim_(r))

    elseif base#inlist(sec,base#qw('_build_perltex_ _build_pdflatex_'))
			let r = {
					\	'proj' : proj,
					\	'sec'  : sec,
					\	}
			call extend(lines , projs#newseclines##_build_tex_(r))

"""newsec_else
    else


"""newsec_else_prompt
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
        else
"""newsec_else_no_prompt
            let seccmd= get(ref,'seccmd','section')

						if strlen(seccmd)
							let title = sec
							let label = 'sec:'.sec
	
							call add(lines,'\' . seccmd . '{'.title.'}')
							call add(lines,'\label{'.label.'}')
							call add(lines,' ')
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

	call extend(header,[ ' ' , '%%file ' . sec, ' ' ])
	call extend(header,[ ' ','%%parent ' . parent_sec ,' '])

	return header
endf
