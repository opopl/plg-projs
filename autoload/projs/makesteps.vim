
function! projs#makesteps#prepare (...)

 try
    cclose
 catch
 endtry
  
 let outdir = projs#var('texoutdir')
 let pdfout = base#path('pdfout')
 call base#mkdir(outdir)

 let g:logfile     = outdir . '/' . proj . '.log'
 let g:tmp_pdffile = outdir . '/' . proj . '.pdf'
 let g:pdffile     = pdfout . '/' . proj . '.pdf'

 let g:TexMode     = projs#var('texmode')
 let g:TexMainFile = projs#proj#name()

 if filereadable(g:logfile)
    call delete(g:logfile)
 endif
 
endfunction

function! projs#makesteps#HTLATEX ()
	
endfunction

function! projs#makesteps#latex (...)
 LFUN TEX_make

 echohl Title
 echo ' Stage latex: LaTeX invocation'
 echohl None

 MakePrg projs

 call projs#makesteps#prepare()
 call TEX_make()

endfunction

function! projs#makesteps#make (...)
 
  try
    cclose
  catch
  endtry

  let texmode = projs#var('texmode')
  let proj    = projs#proj#name()
  
  let outdir  = projs#var('texoutdir')
  call base#mkdir(outdir)

  let pdfout=base#path('pdfout')

  let g:logfile     = outdir . '/' . proj . '.log'
  let g:tmp_pdffile = outdir . '/' . proj . '.pdf'
  let g:pdffile     = pdfout . '/' . proj . '.pdf'

  if filereadable(logfile)
    call delete(logfile)
  endif
      
  let starttime=localtime()
  
  echohl MoreMsg
  echo '  Running TeX ... '
  echohl None
  
  if index([ 'nonstopmode','batchmode' ],texmode) >= 0 
    exe 'silent make!'
  elseif texmode == 'errorstopmode'
    exe 'make!'
  endif

  if filereadable(g:tmp_pdffile)
	call rename(g:tmp_pdffile,g:pdffile)
  endif
  
  let endtime   = localtime()
  let buildtime = endtime-starttime
  
  let g:qlist=[]

  if has('perl')

" perl code {{{ 
"
perl << EOF
#!/usr/bin/env perl

  use strict;
  use warnings;
  
  use Vim::Perl qw( VimEval VimVar process_quickfix_latex );
  use File::Slurp qw( read_file );
  use Data::Dumper;
  use File::Spec::Functions qw(catfile);

  Vim::Perl::init;
  process_quickfix_latex;
  
EOF

"}}}
"
	endif

    call setqflist(g:qlist)
  
    let errors=getqflist()
    let newerrors=[]
  
    for e in errors
      let valid=e['valid']
      let type=e['type']
      "if ( valid && type == 'E' )
      if ( valid )
        if ( type != 'W' ) 
          call add(newerrors,e)
        endif
      endif
    endfor
  
    let errcount=len(newerrors)
    let timemsg=' (' . buildtime . ' secs)' 
  
    if errcount 
      call setqflist(newerrors)
  
      echohl ErrorMsg
      echomsg 'TEX BUILD FAILURE:  ' . errcount . ' errors' . timemsg
      echohl None
  
      copen
    else
      redraw!
      echohl ModeMsg
      echomsg 'TEX BUILD OK:  ' . g:proj . timemsg
      echohl None
    endif
 
endfunction
 
