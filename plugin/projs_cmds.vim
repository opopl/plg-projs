
command! -nargs=* -complete=custom,projs#complete 
	\	ProjView call projs#viewproj(<f-args>) 

