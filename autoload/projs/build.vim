

function! projs#build#logfile (...)
		let exts = ['log']
		let bfiles = projs#build#files({ 
			\	"exts"          : exts,
			\	"add_pdf_built" : 0
			\	})
		let bfile = get(bfiles,-1,'')
		return bfile
endfunction

function! projs#build#action (...)

	let acts = base#qwsort('View Run Cleanup List')
	if a:0
		let act=a:1
	else
		let act = base#getfromchoosedialog({ 
		 	\ 'list'        : acts,
		 	\ 'startopt'    : 'regular',
		 	\ 'header'      : "Actions: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose an action by number: ",
		 	\ })
	endif

"""PrjBuild_Cleanup
	if act == 'Cleanup'
		call projs#build#cleanup()

"""PrjBuild_View
	elseif act == 'View'
		let extstr ='aux log'
		let extstr = input('Extensions for files:',extstr)

		let exts = base#qwsort(extstr)

		let bfiles = projs#build#files({ 
			\	"exts"          : exts,
			\	"add_pdf_built" : 0
			\	})

		let file = base#getfromchoosedialog({ 
		 	\ 'list'        : bfiles,
		 	\ 'startopt'    : 'regular',
		 	\ 'header'      : "Build files available for viewing: ",
		 	\ 'numcols'     : 1,
		 	\ 'bottom'      : "Choose a file by number: ",
		 	\ })
		call base#fileopen(file)

	endif
endfunction

function! projs#build#cleanup (...)
	let bfiles = projs#build#files()

	if !len(bfiles)
		echo 'No build files to remove!'
		return
	endif
	
	let rm = 'y'
	if rm == 'y'
		for bfile in bfiles
			if filereadable(bfile)
				  call delete(bfile)

			elseif isdirectory(bfile)
          if has('win32')
            let cmd = 'rmdir /q/s ' . bfile
            let ok = base#sys({ 
	             \   "cmds"         : [cmd],
	             \   "split_output" : 0,
	             \   })
          endif
			endif
		endfor
	endif

endfunction

" used in: 
" 	projs#build#run
" examples:
" 	projs#build#setmake({ 
" 		\	'opt'       : 'latexmk',
" 		\	'texoutdir' : dir 
" 		\	})
"
function! projs#build#setmake (ref)
 let ref = a:ref

 let prompt = get(ref,'prompt',0)

 let opt       = projs#varget('prjmake_opt','')
 let texoutdir = projs#varget('texoutdir','')
	
 let makeef=''
 let makeef = base#file#catfile([ texoutdir , 'make_'.opt.'.log' ])

 if opt == 'single_run'
 	call make#makeprg('projs_single_latex',{ 'echo' : 0 })

 elseif opt == 'latexmk'
 	call make#makeprg('projs_latexmk',{ 'echo' : 0 })
	let makeef = base#file#catfile([ texoutdir , 'make.log' ])

 elseif opt == 'htlatex'
 	call make#makeprg('projs_htlatex',{ 'echo' : 0 })

 elseif opt == 'bibtex'
 	call make#makeprg('projs_bibtex',{ 'echo' : 0 })

 elseif opt == 'makeindex'
 	call make#makeprg('projs_makeindex',{ 'echo' : 0 })

 elseif opt == 'build_pdflatex'
 	call make#makeprg('projs_build_pdflatex',{ 'echo' : 0 })

 elseif opt == 'build_htlatex'
 	call make#makeprg('projs_build_htlatex',{ 'echo' : 0 })

 elseif opt == 'build_perltex'
 	call make#makeprg('projs_build_perltex',{ 'echo' : 0 })

 endif

 call projs#varset('prjmake_opt',opt)

 if strlen(makeef)
 	exe 'setlocal makeef='.makeef
 endif

 if prompt
		let makeprg=input('makeprg:',&makeprg)
		exe 'setlocal makeprg='.escape(makeprg,' "\')
	
		let makeef=input('makeef:',&makeef)
		exe 'setlocal makeef='.makeef
 endif

endfunction

function! projs#build#aftermake ()
 
 let opt    = projs#varget('prjmake_opt','')

 if opt == 'latexmk'

 elseif opt == 'build_htlatex'

 endif
	
endfunction

" projs#build#run ()
" projs#build#run ('single_run')
" projs#build#run ({ 'opt' : 'use_latexmk' })
" projs#build#run ({ 'opt' : 'use_htlatex'})
"
" projs#build#run ({ 'buildmode' : 'make'})
" projs#build#run ({ 'buildmode' : 'base_sys'})
"
"
function! projs#build#is_pdfo (opt)
 let opt  = a:opt
 let pdfo = base#qw('latexmk single_run')

 let x = 0
 let x = base#inlist(opt,pdfo)

 return x

endf

function! projs#build#set_pdfout (...)
	let ref    = get(a:000,0,{})
	let prompt = get(ref,'prompt',0)

	let pdfout = projs#varget('pdfout','')
	if prompt
		 	let pdfout = input('pdfout: ',pdfout)
			call projs#varset('pdfout',pdfout)
	endif
	return pdfout
endf

function! projs#build#set_texjobname (...)
	let ref    = get(a:000,0,{})
	let prompt = get(ref,'prompt',0)

	let proj = projs#proj#name()
 let texjobname = proj

 if prompt
 	let texjobname = input('texjobname: ',texjobname)
 endif

 call projs#varset('texjobname',texjobname)
 return texjobname

endf

function! projs#build#set_texmode (...)
	let ref    = get(a:000,0,{})
	let prompt = get(ref,'prompt',0)

	let texmode = projs#varget('texmode','')
	if !len(texmode) | call projs#warn('texmode is not defined!') | endif 

	if prompt
	 		let texmode = input('texmode: ',texmode,'custom,tex#complete#texmodes')
	endif

	return texmode

endf

function! projs#build#set_texoutdir (...)
	let ref=get(a:000,0,{})
	
	let bnum = projs#var('buildnum')
  let texoutdir = projs#varget('texoutdir','')

 	let opt    = projs#varget('prjmake_opt','')
	
	if projs#build#is_pdfo(opt)
		let bnum      = projs#varget('buildnum',1)
		let texoutdir = base#file#catfile([ projs#builddir(), bnum ])
	
	elseif opt == 'build_htlatex'
		let texoutdir = base#file#catfile([ projs#builddir(), 'b_htlatex' ])
	
	elseif opt == 'build_perltex'
		let texoutdir = base#file#catfile([ projs#builddir(), 'b_perltex' ])
	
	elseif opt == 'build_pdflatex'
		let texoutdir = base#file#catfile([ projs#builddir(), 'b_pdflatex' ])
	
	endif

 call base#mkdir(texoutdir)
 call projs#varset('texoutdir',texoutdir)

 return texoutdir
endf

function! projs#build#make_invoke (...)
 let ref       = get(a:000,0,{})

 let opt       = projs#varget('prjmake_opt','')
 let buildmode = projs#varget('buildmode','')
 let texmode   = projs#varget('texmode','')
 let bnum      = projs#varget('builnum',1)
 let verbose   = projs#varget('verbose',0)

 if projs#build#is_pdfo(opt)
  	let txt = 'PDF Build number     => '  . bnum 
		call base#log( split(txt,"\n") )
 endif

 let ok = 0

 let starttime   = localtime()
 call projs#varset('build_starttime',starttime)

 if buildmode == 'make'
	 " verbose parameter is set at the beginning of the method
	 " 		projs#build#run()
	 if verbose
		 let txt=''
		 let txt.= "\n" .  '-------------------------'
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  'Running make:'
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  ' Current directory:           ' . getcwd()
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  ' ( Vim opt ) &makeprg      => ' . &makeprg
		 let txt.= "\n" .  ' ( Vim opt ) &makeef       => ' . &makeef
		 let txt.= "\n" .  ' ( Vim opt ) &errorformat  => ' . &efm
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  ' Build opt                 => ' . opt 
		 let txt.= "\n" .  ' Texmode                   => ' . texmode
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  '-------------------------'

		 call base#log( split(txt,"\n") )
	 endif

 "  if exists(":AsyncMakeGreen")
		 "if index([ 'nonstopmode','batchmode' ],texmode) >= 0 
			 "exe 'silent AsyncMakeGreen'
		 "elseif texmode == 'errorstopmode'
			 "exe 'AsyncMakeGreen'
		 "endif
	 "else
	 "endif
	 "
		 echo 'make: prjmake_opt => ' . opt . ', texmode => ' . texmode . ', bnum => ' . bnum 
			 
		 if index([ 'nonstopmode','batchmode' ],texmode) >= 0 
		   exe 'silent make!'
		 elseif texmode == 'errorstopmode'
		   exe 'make!'
		 endif

 elseif buildmode == 'base_sys'
	 let cmd = &makeprg

	 " verbose parameter is set at the beginning of the method
	 " 		projs#build#run()
	 if verbose
		 let txt.= "\n" .  '-------------------------'
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  'Running command:'
		 let txt.= "\n" .  ' ' . cmd
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  ' Current directory:           ' . getcwd()
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  ' Vim make-related options:'
		 let txt.= "\n" .  ' 		&makeprg      => ' . &makeprg
		 let txt.= "\n" .  ' 		&makeef       => ' . &makeef
		 let txt.= "\n" .  ' 		&errorformat  => ' . &efm
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  ' Build opt         => ' . opt 
		 let txt.= "\n" .  ' Texmode           => ' . texmode
		 let txt.= "\n" .  ' '
		 let txt.= "\n" .  '-------------------------'

		 call base#log( split(txt,"\n") )
	 endif

	 	let ok = base#sys({ 
			\ "cmds" : [ cmd ],
			\	})

		let sysoutstr = base#varget('sysoutstr','')
	 	let sysout    = base#varget('sysout',[])

		 if ok
		 		echo 'BUILD OK'
		 else
		 		echo 'BUILD FAIL'
		 		call base#text#bufsee({'lines':sysout})
		 endif
	endif

	return ok

endfunction

function! projs#build#run (...)
 call projs#varset('verbose',1)

 try
    cclose
 catch
 endtry

 let opt =  projs#varget( 'prjmake_opt', 'latexmk')

 let ref = {
				\	"prompt"    : 0,
				\	"buildmode" : projs#varget('buildmode','make'),
			 	\	}

 let refadd = get(a:000,0,{})
 call extend(ref,refadd)

 let buildmode = get(ref,'buildmode','')

 let prompt = get(ref,'prompt',0)
 let opt    = get(ref,'opt',opt)

 if prompt | let opt = input('Build opt: ', opt ,'custom,projs#complete#prjmake') | endif
 call projs#varset('prjmake_opt' , opt)

 call base#log(' Stage latex: LaTeX invocation')

 let proj = projs#proj#name()

	call projs#setbuildvars()

	let texoutdir   = projs#build#set_texoutdir()
	let texmode     = projs#build#set_texmode({ 'prompt' : prompt })
	let texjobname  = projs#build#set_texjobname({ 'prompt' : prompt })
	let pdfout      = projs#build#set_pdfout({ 'prompt' : prompt })

	call projs#build#setmake({
		\ "prompt"    : prompt,
		\	})

	if opt =~ '^build_'	
		call projs#newsecfile('_'.opt.'_')
	endif

	let ok = projs#build#make_invoke()
	
	call projs#build#pdf_process()
	
	call projs#build#qflist_process({ 
		\	"prompt" : prompt,
		\	})

endfunction

function! projs#build#pdf_process ()

 	let opt    = projs#varget('prjmake_opt','')
	let bnum   = projs#varget('buildnum')
	let pdfout = projs#varget('pdfout','')

	let texoutdir  = projs#varget('texoutdir','')
	let texjobname = projs#varget('texjobname','')

	let proj   = projs#proj#name()

 let pdffile_tmp = base#file#catfile([ texoutdir, texjobname . '.pdf'])

 if projs#build#is_pdfo(opt)
	 let pdffile_final = base#file#catfile([ pdfout, proj .bnum.'.pdf'])
	
	 let dests=[]
	 call add(dests,pdffile_final)
	
	 "" copy to $PDFOUT dir
	 let pdffile_env = base#file#catfile([ base#path('pdfout'), proj.'.pdf'])
	 let bp_pdfout   = base#path('pdfout')
	
	 call base#mkdir(bp_pdfout)
	 if isdirectory(bp_pdfout)
	 		call add(dests,pdffile_env)
	 endif
	
	 let pfile = pdffile_tmp
	 if filereadable(pfile) && getfsize(pfile)
		for dest in dests
			let ok = base#file#copy(pfile,dest)
		
			if ok
			 	let prf = { 'prf' : '' }
			 	call base#log([
			 		\	"PDF file copied to:",
			 		\	"		" . dest,
			 		\	],prf) 
			endif
		endfor
	
	 else
	 	 let prf = { 'prf' : '' }
		 call base#log([ 'NO PDF file: ' , pfile],prf)
	 endif
 endif
	
endfunction

function! projs#build#qflist_process (...)

 let starttime = projs#varget('build_starttime')
 let proj      = projs#proj#name()

 let endtime   = localtime()
 let starttime = projs#var('build_starttime')

 let buildtime = endtime-starttime
 let timemsg   = ' (' . buildtime . ' secs)'

 let qflist = copy(getqflist())

 let pats = tex#parser#latex#patterns()

 let patids = base#qw('latex_error error')

 let keep = 0
 let newlist= []

 let i = 0
 for item in qflist
	let keep = 0

	let text = get(item,'text')
	let lnum = get(item,'lnum',0)

	if ! lnum
		for patid in patids
			let pat = get(pats,patid,'')
			if strlen(pat)
				if text =~ pat
					echo text
				endif
			endif
		endfor
	else
		let keep = 1
	endif

	if keep 
		call add(newlist,item)
	endif
 endfor

	call setqflist(newlist)
	let errcount = len(newlist)
	
	redraw!
	if !errcount
		echohl ModeMsg
		echomsg 'TEX BUILD OK:  ' . proj . timemsg
		echohl None
	else
		echohl ErrorMsg
		echomsg 'TEX BUILD FAILURE:  ' . errcount . ' errors' . timemsg
		echohl None
		copen
	endif

	

endfunction

" echo projs#build#files({ 
" 	\	"exts" : ["pdf"],
" 	\	"add_pdf_built" : 1,
" 	\	"add_other" : 1,
" 	\	})

function! projs#build#files (...)
	let ref = {}
	if a:0 | let ref = a:1 | endif

	let exts_other = get(ref,'exts',[ ])

	let pdfout = projs#var('pdfout')
	let proj   = projs#proj#name()

	let bfiles = []

	let defs={
		\	'relpath' : 0
		\ }
	let do ={}

	for d in keys(defs)
		let do[d]=get(ref,d,defs[d])
	endfor


	" ---------------- get built (PDF/other extension) files
	if get(ref,'add_pdf_built',1)
		let fref = {
			\ "dirs" : [pdfout],
			\ "pat"  : '^'.proj.'\d+'.'\.pdf',
			\ "relpath" : do.relpath,
			\ "subdirs" : 0,
			\ "exts"    : ["pdf"],
			\ }
		let pdffiles = base#find(fref)
	
		call extend(bfiles,pdffiles)
	endif

	" ---------------- get all other build files
	if get(ref,'add_other',1)
		let builddir = projs#builddir()
		let files = []
	
		let fref = {
			\ "dirs" : [builddir],
			\ "relpath" : do.relpath,
			\ "subdirs" : 1,
			\ "exts"    :  exts_other,
			\ }
	
		let files = base#find(fref)
	endif

	call extend(bfiles,files)

	return bfiles

endfunction
