
command! -nargs=* -complete=custom,projs#complete 
	\	PrjView call projs#viewproj(<f-args>) 

