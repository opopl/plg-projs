
function! projs#build#cleanup (...)
	let bfiles = projs#build#files()

	if !len(bfiles)
		echo 'No build files to remove!'
		return
	endif
	
	echohl Title
	echo 'Files to remove:'
	echohl MoreMsg
	for bfile in bfiles
		echo "\t" . bfile
	endfor
	echohl None

	let rm = input('Remove these files? (y/n):','y')
	if rm == 'y'
		echo "\n"
		for bfile in bfiles
			echo "\t" . 'Removing file: ' . bfile 
			call delete(bfile)
		endfor
	endif

endfunction


" projs#build#run ()
" projs#build#run ('single_run')
" projs#build#run ('use_latexmk')
" projs#build#run ('use_htlatex')
"
function! projs#build#run (...)

 try
    cclose
 catch
 endtry

 " simple latex run
 let opt = 'single_run'
 if a:0
 	let opt = a:1
 endif

 echohl Title
 echo ' Stage latex: LaTeX invocation'
 echohl None

 let proj = projs#proj#name()
 call projs#setbuildvars()

 let bnum = projs#var('buildnum')
 let texoutdir = base#file#catfile([ projs#builddir(), bnum ])

 call base#mkdir(texoutdir)
 call projs#var('texoutdir',texoutdir)

 let texmode    = projs#var('texmode')
 let texjobname = proj

 let pdfout = projs#var('pdfout')

 call projs#var('texjobname',texjobname)

 echo 'Build number     => '  . bnum 

 if opt == 'single_run'
 	call make#makeprg('projs_pdflatex',{ 'echo' : 0 })
 elseif opt == 'use_latexmk'
 	call make#makeprg('projs_latexmk',{ 'echo' : 0 })
 elseif opt == 'use_htlatex'
 	call make#makeprg('projs_htlatex',{ 'echo' : 0 })
 endif

 let starttime   = localtime()

 let pdffile_tmp = base#file#catfile([ texoutdir, texjobname . '.pdf'])

 if index([ 'nonstopmode','batchmode' ],texmode) >= 0 
   exe 'silent make!'
 elseif texmode == 'errorstopmode'
   exe 'make!'
 endif

 let pdffile_final = base#file#catfile([ pdfout, proj .bnum.'.pdf'])

 if filereadable(pdffile_tmp)
 	echo "PDF file created"

 	call rename(pdffile_tmp,pdffile_final)
 endif

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

function! projs#build#files (...)
	let pdfout = projs#var('pdfout')
	let proj   = projs#proj#name()

	let bfiles = []

	" ---------------- get built PDF files
	let fref = {
		\ "dirs" : [pdfout],
		\ "pat"  : '^'.proj.'\d\+'.'\.pdf',
		\ "relpath" : 0,
		\ "subdirs" : 0,
		\ "exts" : ["pdf"],
		\ }
	let pdffiles = base#find(fref)

	call extend(bfiles,pdffiles)

	" ---------------- get all other build files
	let builddir = projs#builddir()
	let files = []

	let fref = {
		\ "dirs" : [builddir],
		\ "relpath" : 0,
		\ "subdirs" : 1,
		\ }

	let files = base#find(fref)

	call extend(bfiles,files)

	return bfiles

endfunction
