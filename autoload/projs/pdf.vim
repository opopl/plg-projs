

function! projs#pdf#invoke (...)
  let act = get(a:000,0,'')

  let acts = base#varget('projs_opts_PrjPdf',[])

  let proj = projs#proj#name()

  let fmt_sub = 'projs#pdf#invoke#%s'
  let front = [
      \ 'See also:' ,
      \ '   projs#pdf#invoke' ,
      \ '   projs#pdf#invoke#bld_view' ,
      \ 'Current project:' , "\t" . proj,
      \ 'Possible PrjPdf actions: ' 
      \ ]
  let desc = base#varget('projs_desc_PrjPdf',{})

  let Fc = projs#fc#match_proj({ 'proj' : proj })

  call base#util#split_acts({
    \ 'act'     : act,
    \ 'acts'    : acts,
    \ 'desc'    : desc,
    \ 'front'   : front,
    \ 'fmt_sub' : fmt_sub,
    \ 'Fc'      : Fc,
    \ })

endf

if 0
  Usage:
     call projs#pdf#view ()
     call projs#pdf#view ('',VIEWER)
     call projs#pdf#view ('','',TYPE)

     call projs#pdf#view ({ 
        \ 'proj'   : PROJ,
        \ 'viewer' : VIEWER,
        \ 'type'   : TYPE 
        \ })
  
  Used by:
     PrjPdf
  
     PrjAct pdf_view
     projs#action#pdf_view
endif

function! projs#pdf#view (...)
  let ref = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let viewer_id = get(ref,'viewer','evince')
  let viewer    = base#exefile#path(viewer_id)

  let type  = get(ref,'type','bld')

  let pdf_files = projs#pdf#path({ 
    \ 'proj' : proj ,
    \ 'type' : type ,
    \ })

  if !len(pdf_files)
    let msg = 'PDF files NOT READABLE!'
    call base#warn({ 
      \ 'rdw'    : 1,
      \ 'text'   : msg,
      \ 'prefix' : 'projs#pdf#view' })
    return
  endif

  let targets = []
  let pats = {
    \ 'bld'  : printf('^%s\.\(.*\).pdf$',proj),
    \ 'bare' : printf('^%s.pdf$',proj),
    \ } 

  let pat = get(pats,type,'')

  let pdf_file = ''
  if type == 'bld'
	  let d_files = {}
	  for file in pdf_files
	    let file_b = fnamemodify(file,':t')
	    let t      = substitute(file_b,pat,'\1','g')

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
  elseif type == 'bare'
    let pdf_file = get(pdf_files,0,'')
  endif

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
    call base#rdw_printf([ 'Opened PDF file: %s',pdf_file ],'WildMenu')
  endif
endfunction

if 0
  Usage
    let pdf = projs#pdf#path()

    let pdf = projs#pdf#path({ 'type' : 'bld'})
    let pdf = projs#pdf#path({ 'type' : 'bare'})
  Call tree
    Called by
      projs#pdf#view
      projs#pdf#delete
endif

function! projs#pdf#path (...)
  let ref = get(a:000,0,{})

  let type = get(ref,'type','bld')

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let pdffin  = projs#varget('pdffin','')

  let a = [ pdffin, projs#rootid(), proj ]
  let pdf_dir = base#file#catfile(a)

  let pats = {
      \  'bld'   : printf('^%s\.(.*)\.pdf',proj),
      \  'bare'  : printf('^%s\.pdf',proj),
      \  }
  let pat = get(pats,type,'')

  let pdf_files = base#find({ 
    \ "dirs"    : [pdf_dir],
    \ "exts"    : ['pdf'],
    \ "relpath" : 0,
    \ "subdirs" : 0,
    \ "pat"     : pat,
    \ })

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

