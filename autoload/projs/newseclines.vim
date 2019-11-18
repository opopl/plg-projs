
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
