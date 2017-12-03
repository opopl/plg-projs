

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

 call projs#varset('prjmake_opt',opt)

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

function! projs#build#run (...)
 let verbose=1

 try
    cclose
 catch
 endtry

 let opt =  projs#varget('prjmake_opt','latexmk')

 let ref = {
				\	"prompt"    : 0,
				\	"buildmode" : projs#varget('buildmode','make'),
			 	\	}

 let refadd = get(a:000,0,{})
 call extend(ref,refadd)

 let buildmode = get(ref,'buildmode','')

 let prompt = get(ref,'prompt',0)
 let opt    = get(ref,'opt',opt)

 call projs#varset('prjmake_opt',opt)

 if prompt | let opt = input('Build opt: ',opt,'custom,projs#complete#prjmake') | endif

 echohl Title
 echo ' Stage latex: LaTeX invocation'
 echohl None

 if opt == 'latexmk'
		call projs#varset('buildmode','base_sys')
		call projs#varset('buildmode','make')
 else
		call projs#varset('buildmode','make')
 endif

 let proj = projs#proj#name()
 call projs#setbuildvars()

 let bnum=1
 if projs#build#is_pdfo(opt)
	 let bnum      = projs#varget('buildnum',1)
	 let texoutdir = base#file#catfile([ projs#builddir(), bnum ])
 elseif opt == 'build_htlatex'
	 let texoutdir = base#file#catfile([ projs#builddir(), 'b_htlatex' ])
 endif

 call base#mkdir(texoutdir)
 call projs#varset('texoutdir',texoutdir)

 let texmode = projs#varget('texmode','')
 if !len(texmode) | call projs#warn('texmode is not defined!') | endif 

 if prompt
 		let texmode = input('texmode: ',texmode,'custom,tex#complete#texmodes')
 endif

 let texjobname = proj

 if prompt
 	let texjobname = input('texjobname: ',texjobname)
 endif

 call projs#varset('texjobname',texjobname)

 let pdfout = projs#varget('pdfout')
 if prompt
		 	let pdfout = input('pdfout: ',pdfout)
			call projs#varset('pdfout',pdfout)
 endif

 call projs#build#setmake({
 				\ "opt"       : opt,
  			\ "texoutdir" : texoutdir,
 			\	})

 let starttime   = localtime()
 call projs#varset('build_starttime',starttime)

 let pdffile_tmp = base#file#catfile([ texoutdir, texjobname . '.pdf'])

 if projs#build#is_pdfo(opt)
  	echo 'PDF Build number     => '  . bnum 
 endif

 let htmlo   = base#qw('build_htlatex')

 let is_htmlo = 0
 let is_htmlo = base#inlist(opt,htmlo)

 if is_htmlo
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


 if buildmode == 'make'
	 " verbose parameter is set at the beginning of the method
	 " 		projs#build#run()
	 if verbose
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
		 echo ' Texmode                   => ' . texmode
		 echo ' '
		 echo ' '
		 echo '-------------------------'
	 endif
	
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
		 echo '-------------------------'
		 echo ' '
		 echo 'Running command:'
		 echo ' ' . cmd
		 echo ' '
		 echo ' Current directory:           ' . getcwd()
		 echo ' '
		 echo ' Vim make-related options:'
		 echo ' 		&makeprg      => ' . &makeprg
		 echo ' 		&makeef       => ' . &makeef
		 echo ' 		&errorformat  => ' . &efm
		 echo ' '
		 echo ' Build opt         => ' . opt 
		 echo ' Texmode           => ' . texmode
		 echo ' '
		 echo '-------------------------'
	 endif

	 let ok = base#sys({ 
			\ "cmds" : [ cmd ],
			\	})

	 let sysoutstr = base#varget('sysoutstr','')
	 let sysout    = base#varget('sysout',[])

	 let qflist=[]
	 for line in sysout
	 endfor

	 if ok
	 		echo 'BUILD OK'
	 else
	 		echo 'BUILD FAIL'
	 		call base#text#bufsee({'lines':sysout})
	 endif

 endif

 call projs#build#aftermake({ "opt" : opt })

	 "" pdf output
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
	
	 if filereadable(pdffile_tmp)
		for dest in dests
			let ok = base#file#copy(pdffile_tmp,dest)
		
			if ok
			 	echo "PDF file copied to:"
			 	echo " " . dest
			endif
		endfor
	
	 endif
	 "" html output
 elseif is_htmlo
 endif

 call projs#build#qflist_process({ 
		\	"prompt" : prompt, 
		\	"opt" : opt 
		\	})

endfunction

function! projs#build#qflist_process (...)

 let starttime = projs#varget('build_starttime')
 let proj      = projs#proj#name()

 let endtime   = localtime()
 let buildtime = endtime-starttime
 let timemsg   = ' (' . buildtime . ' secs)'

 let qflist = copy(getqflist())

 let pats = tex#parser#latex#patterns()

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
