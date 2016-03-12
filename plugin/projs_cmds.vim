
command! -nargs=* -complete=custom,projs#complete 
	\	PrjView  call projs#viewproj(<f-args>) 

command! -nargs=* -complete=custom,projs#complete
	\	PrjNew call projs#new(<f-args>) 

command! -nargs=* -complete=custom,projs#complete
	\	PrjRename call projs#renameproject(<f-args>)

command! -nargs=* -complete=custom,projs#complete
	\	PrjRemove call projs#removeproject(<f-args>)

command! -nargs=* -complete=custom,projs#complete#varlist
	\	PrjVarEcho call projs#varecho(<f-args>)
 
