
command! -nargs=* -complete=custom,projs#complete 
	\	PrjView call projs#viewproj(<f-args>) 

command! -nargs=* -complete=custom,projs#complete 
	\	VPROJ call projs#viewproj(<f-args>) 

