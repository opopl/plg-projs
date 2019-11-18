
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

function! projs#newseclines#regular#_vim_ (...)
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
