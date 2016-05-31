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

	if act == 'Cleanup'
		call projs#build#cleanup()
	elseif act == 'View'
		let extstr ='aux log'
		let extstr = input('Extensions for files:',extstr)

		let exts = base#qwsort(extstr)

		let bfiles = projs#build#files({ 
			\	"exts" : exts, 
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
	
	"echohl Title
	"echo 'Files to remove:'
	"echohl MoreMsg
	"for bfile in bfiles
		"echo "\t" . bfile
	"endfor
	"echohl None

	"let rm = input('Remove files? (y/n):','y')
	let rm = 'y'
	if rm == 'y'
		"echo "\n"
		for bfile in bfiles
			"echo "\t" . 'Removing file: ' . bfile 
			call delete(bfile)
		endfor
	endif

endfunction

function! projs#build#setmake (ref)
 let ref = a:ref

 let opt        = get(ref,'opt')
 let texoutdir  = get(ref,'texoutdir')
	
 let makeef=''
 let makeef = base#file#catfile([ texoutdir , 'make_'.opt.'.log' ])

 if opt == 'single_run'
 	call make#makeprg('projs_pdflatex',{ 'echo' : 0 })

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

 endif

 call projs#var('prjmake_opt',opt)

 if strlen(makeef)
 	exe 'setlocal makeef='.makeef
 endif

endfunction

function! projs#build#aftermake (...)
 let ref ={}

 if a:0
	let refadd = a:1
	call extend(ref,refadd)
 endif
 let opt = get(ref,'opt')

 if opt == 'latexmk'

 endif
	
endfunction

" projs#build#run ()
" projs#build#run ('single_run')
" projs#build#run ({ 'opt' : 'use_latexmk' })
" projs#build#run ({ 'opt' : 'use_htlatex'})
"
function! projs#build#run (...)

 try
    cclose
 catch
 endtry

 let opt =  projs#varexists('prjmake_opt') ? projs#var('prjmake_opt') : 'latexmk' 

 let ref ={
	\	"prompt" : 0,
 	\	}

 if a:0
	let refadd = a:1
	call extend(ref,refadd)
 endif

 let prompt = get(ref,'prompt',0)
 let opt    = get(ref,'opt',opt)

 if prompt | let opt = input('Build opt: ',opt,'custom,projs#complete#prjmake') | endif

 echohl Title
 echo ' Stage latex: LaTeX invocation'
 echohl None

 let proj = projs#proj#name()
 call projs#setbuildvars()

 let bnum      = projs#var('buildnum')
 let texoutdir = base#file#catfile([ projs#builddir(), bnum ])

 call base#mkdir(texoutdir)
 call projs#var('texoutdir',texoutdir)

 let texmode = projs#var('texmode')

 if prompt
 	let texmode = input('texmode: ',texmode,'custom,tex#complete#texmodes')
 endif

 let texjobname = proj

 if prompt
 	let texjobname = input('texjobname: ',texjobname)
 endif

 call projs#var('texjobname',texjobname)

 let pdfout = projs#var('pdfout')
 if prompt
 	let pdfout = input('pdfout: ',pdfout)
	call projs#var('pdfout',pdfout)
 endif

 call projs#build#setmake({"opt" : opt, "texoutdir" : texoutdir })

 let starttime   = localtime()
 call projs#var('build_starttime',starttime)

 let pdffile_tmp = base#file#catfile([ texoutdir, texjobname . '.pdf'])

 let pdfo    = base#qw('latexmk single_run')
 let is_pdfo = base#inlist(opt,pdfo)

 if is_pdfo
  	echo 'Build number     => '  . bnum 
 endif

 if opt =~ '^build_'
	call projs#newsecfile('_'.opt.'_')
 endif

 if prompt
	let makeprg=input('makeprg:',&makeprg)
	exe 'setlocal makeprg='.escape(makeprg,' "\')

	let makeef=input('makeef:',&makeef)
	exe 'setlocal makeef='.makeef
 endif

 echo '-------------------------'
 echo ' '
 echo 'Running make:'
 echo ' '
 echo ' Current directory:           ' . getcwd()
 echo ' '
 echo ' ( Vim opt ) &makeprg      => ' . &makeprg
 echo ' ( Vim opt ) &makeef       => ' . &makeef
 echo ' ( Vim opt ) &errorformat  => ' . &efm
 echo ' '
 echo ' Build opt                 => ' . opt 
 echo ' '
 echo '-------------------------'

 if index([ 'nonstopmode','batchmode' ],texmode) >= 0 
   exe 'silent make!'
 elseif texmode == 'errorstopmode'
   exe 'make!'
 endif

 call projs#build#aftermake({ "opt" : opt })

 if is_pdfo
	 let pdffile_final = base#file#catfile([ pdfout, proj .bnum.'.pdf'])
	
	 let dests=[]
	 call add(dests,pdffile_final)
	
	 "" copy to $PDFOUT dir
	 let pdffile_env = base#file#catfile([ base#path('pdfout'), proj.'.pdf'])
	 let bp_pdfout = base#path('pdfout')
	
	 call base#mkdir(bp_pdfout)
	 if isdirectory(bp_pdfout)
	 	call add(dests,pdffile_env)
	 endif
	
	 if filereadable(pdffile_tmp)
		for dest in dests
			let ok = base#file#copy(pdffile_tmp,dest)
		
			if ok
			 	echo "PDF file copied to:"
			 	echo " " . dest
			endif
		endfor
	
	     "call rename(pdffile_tmp,pdffile_final)
	 endif
 endif


 call projs#build#qflist_process({ "prompt" : prompt, "opt" : opt })

endfunction

function! projs#build#qflist_process (...)

 let starttime=projs#var('build_starttime')

 let endtime   = localtime()
 let buildtime = endtime-starttime
 let timemsg   = ' (' . buildtime . ' secs)'

 let qflist = copy(getqflist())

 let pats = { 
 	\	'latex_error' : '^\(.*\):\(\d\+\): LaTeX Error:\(.*\)',
 	\	'error' : '^\(.*\):\(\d\+\): ',
	\}
 let patids = base#qw('latex_error error')

 let keep = 0
 let newlist= []

 let i=0
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

 if !errcount
      "redraw!
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
			\ "pat"  : '^'.proj.'\d\+'.'\.pdf',
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
