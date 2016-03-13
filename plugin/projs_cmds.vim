
command! -nargs=* -complete=custom,projs#complete 
	\	PrjView  call projs#viewproj(<f-args>) 

command! -nargs=* -complete=custom,projs#complete
	\	PrjNew call projs#new(<f-args>) 

command! -nargs=* -complete=custom,projs#complete
	\	PrjRename call projs#renameproject(<f-args>)

command! -nargs=* -complete=custom,projs#complete
	\	PrjRemove call projs#proj#remove(<f-args>)

command! -nargs=* -complete=custom,projs#complete#varlist
	\	ProjsVarEcho call projs#varecho(<f-args>)

command! -nargs=* ProjsInit call projs#init()

command! -nargs=* -complete=custom,projs#complete#secnamesbase
  	\ VSECBASE call projs#opensec(<f-args>) 

command! -nargs=* -complete=custom,projs#complete
	\ PrjListFiles call projs#proj#listfiles(<f-args>)

command! -nargs=* -complete=custom,projs#complete
	\ PrjListSecs call projs#proj#listsecnames(<f-args>)

