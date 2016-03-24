
function! projs#makesteps#latex (...)
 "LFUN TEX_make
 "
 try
    cclose
 catch
 endtry

 " simple latex run
 let opt = 'latex'
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

 "echohl WildMenu
 "echo 'texjobname => ' . texjobname 
 "echo 'texoutdir  => ' . texoutdir
 "echo 'texmode    => ' . texmode
 "echo 'pdfout     => ' . pdfout
 "echohl None

 call make#makeprg('projs_pdflatex',{ 'echo' : 0 })
 "call make#makeprg('projs_latexmk',{ 'echo' : 0 })

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

function! projs#makesteps#htlatex ()
	
endfunction

