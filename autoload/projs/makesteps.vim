
function! projs#makesteps#latex (...)
 "LFUN TEX_make
 "
 try
    cclose
 catch
 endtry

 echohl Title
 echo ' Stage latex: LaTeX invocation'
 echohl None

 let proj = projs#proj#name()

 let texoutdir = projs#path([ 'builds', proj ])

 let texmode   = projs#var('texmode')
 let texjobname   = proj . '_' . localtime()

 call base#mkdir(texoutdir)
 call projs#var('texoutdir',texoutdir)
 call projs#var('texjobname',texjobname)

 call make#makeprg('projs_pdflatex',{ 'echo' : 0 })

 let starttime   = localtime()

 let pdfout=base#path('pdfout')
 let pdffile_tmp = base#file#catfile([ texoutdir, texjobname . '.pdf'])

 if index([ 'nonstopmode','batchmode' ],texmode) >= 0 
   exe 'silent make!'
 elseif texmode == 'errorstopmode'
   exe 'make!'
 endif

 let pdfout = projs#path([ 'pdf_built' ])
 call base#mkdir(pdfout)

 let num = 1
 let pdfs = base#find({ 
 	\ "dirs" : [ pdfout ], 
	\ "exts" : ["pdf"],
	\ })
 let nums = map(pdfs,
 	\	"substitute(v:val,'^'.proj.'\\(\\d\\+\\)\\.pdf','\\1','g')")

 if len(nums)
 	let num = nums[-1] + 1
 else
	let num = 1
 endif

 let pdffile_final = base#file#catfile([ pdfout, proj .num.'.pdf'])

 if filereadable(pdffile_tmp)
 	echo "PDF file created"

 	call rename(pdffile_tmp,pdffile_final)
 endif

 let endtime   = localtime()
 let buildtime = endtime-starttime
 let timemsg=' (' . buildtime . ' secs)' 

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

function! projs#makesteps#HTLATEX ()
	
endfunction

