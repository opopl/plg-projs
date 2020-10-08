
if 0
  Usage:
     call projs#pdf#view ()

     call projs#pdf#view ('','evince')
     call projs#pdf#view ('','okular')

     call projs#pdf#view (proj)
  
  Used by:
     PrjPdfView
  
     PrjAct pdf_view
     projs#action#pdf_view
endif

function! projs#pdf#view (...)

  let proj_a = get(a:000,0,'')
  let proj = len(proj_a) ? proj_a : projs#proj#name()

  let viewer_id = get(a:000,1,'evince')
  let viewer  = base#exefile#path(viewer_id)

  let pdf_files = projs#pdf#path(proj)

  if !len(pdf_files)
    let msg = 'PDF files NOT READABLE!'
    call base#warn({ 
			\	'rdw'    : 1,
			\	'text'   : msg,
			\	'prefix' : 'projs#pdf#view' })
    return
  endif

	let targets = []
	let pat = printf('^%s\.\(.*\).pdf$',proj)

	let d_files = {}
	for file in pdf_files
		let file_b = fnamemodify(file,':t')
		let t = substitute(file_b,pat,'\1','g')
		if len(t)
			call add(targets,t)
			call extend(d_files,{ t : file })
		endif
	endfor

	let target = '' 
	if len(targets) == 1
		let target = get(targets,0,'')
	endif

	while !len(target)
		call base#varset('this',targets)
		let target = input('target:','','custom,base#complete#this')
	endw

	let pdf_file = get(d_files,target,'')

  let size = base#file#size(pdf_file)
  if !size
    let msg = 'PDF file ZERO SIZE: ' . pdf_file
    call base#warn({ 'text' : msg , 'prefix' : 'projs#pdf#view', 'rdw' : 1 })
    return
  endif

  if filereadable(pdf_file)
    if has('win32')
     let ec= 'silent! !start '.viewer.' '.pdf_file
    else  
     let ec= 'silent! !'.viewer.' '.pdf_file . ' &'
    endif

    exe ec
    redraw!
  endif
endfunction

if 0
  Usage
    let pdf = projs#pdf#path('aa')
    let pdf = projs#pdf#path('aa','pwg')
  Call tree
    Called by
      projs#pdf#view
      projs#pdf#delete
endif

function! projs#pdf#path (...)
  let proj    = get(a:000,0,projs#proj#name())

  let qw = get(a:000,1,'')

  let pdffin  = projs#varget('pdffin','')

  let a = [ pdffin, projs#rootid(), proj ]
  call extend(a,split(qw,' '))
  let pdf_dir = base#file#catfile(a)

	let pdf_files = base#find({ 
		\	"dirs"    : [pdf_dir],
		\	"exts"    : ['pdf'],
		\	"relpath" : 0,
		\	"subdirs" : 0,
		\	"pat"     : printf('^%s\.(.*)\.pdf',proj),
		\	})

  return pdf_files
endfunction

function! projs#pdf#delete (...)
  let proj    = get(a:000,0,projs#proj#name())

  let pdffile = projs#pdf#path(proj)

  if !filereadable(pdffile)
    redraw!
    echohl Question
    echo 'No PDF file! Nothing to delete.'
    echohl None
    return
  endif

  let yn = input('delete PDF file? (1/0): ', 1)
  if !yn | return | endif

  call delete(pdffile)
  if !filereadable(pdffile)
    redraw!
    echohl MoreMsg
    echo 'PDF file has been deleted.'
    echohl None
  endif

endfunction

