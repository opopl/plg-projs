
"		called by:
"			projs#sec#new
"
function! projs#newseclines#fig_num (sec)
	let sec = a:sec

	let lines = []

	let num = substitute(sec,'^fig_\(.*\)$','\1','g')

	let num_dot = substitute(num,'_','.','g')

	call add(lines,'	')
	call add(lines,'\renewcommand{\thefigure}{'.num_dot.'}')
	call add(lines,'	')
	call add(lines,'\begin{figure}[ht]')
	call add(lines,'	\begin{center}')
	call add(lines,'		\PrjPicW{'.num.'}{0.7}')
	call add(lines,'	\end{center}')
	call add(lines,'	')
	call add(lines,'	\caption{')
	call add(lines,'	')
	call add(lines,'	}')
	call add(lines,'	\label{fig:'.num.'}')
	call add(lines,'\end{figure}')
	call add(lines,'	')

	return lines
endfunction

function! projs#newseclines#_vim_ (...)
	let ref = get(a:000,0,{})

	let lines = []

	let proj      = get(ref,'proj','')
	let projtype  = get(ref,'projtype','')

  let q_proj     = txtmy#text#quotes(proj)
  let q_projtype = txtmy#text#quotes(projtype)

  call add(lines,' ')
  call add(lines,'"""_vim_ ')
  call add(lines,' ')
  call add(lines,'let s:projtype ='.q_projtype)
  call add(lines,'let s:proj     ='.q_proj)
  call add(lines,' ')
  call add(lines,'call projs#proj#name(s:proj)')
  call add(lines,'call projs#proj#type(s:projtype)')
  call add(lines,' ')
  call add(lines,'PrjVarSet exe_latex pdflatex ')
  call add(lines,' ')

	return lines
endfunction

function! projs#newseclines#_build_tex_ (...)
	let ref = get(a:000,0,{})
		
	let proj = get(ref,'proj','')
	let sec  = get(ref,'sec','')
	
	let lines = []

	let type = substitute(sec,'^_build_\(\w\+\)_$','\1','g')
	let tex_exe = type
		
	let outd = [ 'builds', proj, 'b_' . type ]
		
	let pcwin = [ '%Bin%' ]
	let pcunix = [ '.' ]

	call extend(pcwin,outd)
	call extend(pcunix,outd)
		
	let outdir_win = base#file#catfile(pcwin)
		
	let outdir_unix = base#file#catfile(pcunix)
	let outdir_unix = base#file#win2unix(outdir_unix)
		
	let tex_opts = []
	if type == 'perltex'
		call add(tex_opts,'--latex=pdflatex --nosafe')
	endif

	call add(tex_opts,' -file-line-error ')
	call add(tex_opts,' -interaction nonstopmode ')
	call add(tex_opts,' -output-directory='. outdir_unix)
		
	let lns = {
		\ 'texcmd'    : '%tex_exe% %tex_opts% ' . proj ,
		\ 'bibtex'    : 'bibtex '    . proj            ,
		\ 'makeindex' : 'makeindex ' . proj            ,
		\ }
	let bibfile = projs#sec#file('_bib_')

	call add(lines,' ')
	call add(lines,'@echo off ')
	call add(lines,' ')
	call add(lines,'set Bin=%~dp0')
	call add(lines,'cd %Bin%')
	call add(lines,' ')
	call add(lines,'set tex_exe='.tex_exe)
	call add(lines,' ')
	call add(lines,'set tex_opts=')
	for opt in tex_opts
	call add(lines,'set tex_opts=%tex_opts% ' . opt)
	endfor
	call add(lines,' ')
	call add(lines,'set outdir='.outdir_win)
	call add(lines,'md %outdir%')
	call add(lines,' ')
	call add(lines,'set bibfile='.bibfile)
	call add(lines,' ')
	call add(lines,'copy %bibfile% %outdir%')
	call add(lines,' ')
	call add(lines,lns.texcmd  )
	call add(lines,'rem --- bibtex makeindex --- ')
	call add(lines,'cd %outdir% ')
	call add(lines,lns.bibtex  )
	call add(lines,lns.makeindex  )
	call add(lines,'rem ------------------------ ')
	call add(lines,' ')
	call add(lines,'cd %Bin% ')
	call add(lines,lns.texcmd  )
	call add(lines,lns.texcmd  )
	call add(lines,' ')

	let origin = base#file#catfile([ outdir_win, proj.'.pdf'])
	
	let dests = []
	
	call add(dests,'%Bin%\pdf_built\b_'.proj.'.pdf' )
	call add(dests,'%PDFOUT%\b_'.type.'_'.proj.'.pdf' )
	call add(dests,'%PDFOUT%\'.proj.'.pdf' )
	
	for dest in dests
		call add(lines,'copy '.origin.' '.dest)
		call add(lines,' ')
	endfor

		return lines
endfunction
