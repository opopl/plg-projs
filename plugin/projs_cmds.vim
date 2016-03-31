
"command! -nargs=* -complete=custom,projs#complete#projsdirslist
command! -nargs=* -complete=custom,base#complete#CD          ProjsInit
	\ call projs#init(<f-args>)

command! -nargs=* -complete=custom,projs#complete#varlist    ProjsVarEcho 
	\ call projs#varecho(<f-args>)

command! -nargs=* -complete=custom,projs#complete#gitcmds    ProjsGit
	\ call projs#git(<f-args>)

command! -nargs=* -complete=custom,projs#complete            PrjView
	\ call projs#viewproj(<f-args>) 

command! -nargs=* -complete=custom,projs#complete            PrjNew
	\ call projs#new(<f-args>) 

command! -nargs=* -complete=custom,projs#complete#prjmake    PrjMake
	\ call projs#prjmake(<f-args>)

command! -nargs=* -complete=custom,projs#complete            PrjRename
	\ call projs#renameproject(<f-args>)

command! -nargs=* -complete=custom,projs#complete            PrjRemove
	\ call projs#proj#remove(<f-args>)

command! -nargs=* -complete=custom,projs#complete#secnames   PrjJoin
	\ call projs#filejoinlines()

command! -nargs=* -complete=custom,projs#complete#grep       PrjGrep
	\ call projs#grep(<f-args>)

command! -nargs=* -complete=custom,projs#complete#update     PrjUpdate
	\ call projs#update(<f-args>)

command! -nargs=* -complete=custom,projs#complete#secnamesall PrjSecNew
	\ call projs#newsecfile(<f-args>)

command! -nargs=* -complete=custom,projs#complete#secnames PrjSecRename
	\ call projs#sec#rename(<f-args>)

command! -nargs=* -complete=custom,projs#complete#secnames PrjSecRemove
	\ call projs#sec#remove(<f-args>)

command! -nargs=* -complete=custom,projs#complete          PrjListFiles 
	\	call projs#proj#listfiles(<f-args>)

command! -nargs=* -complete=custom,projs#complete          PrjListSecs 
	\	call projs#proj#listsecnames(<f-args>)

command! -nargs=* -complete=custom,projs#complete#prjgit   PrjGit 
	\	call projs#proj#git(<f-args>)

"command! -nargs=* -complete=custom,projs#complete
	"\ PrjMake call projs#prjmake(<f-args>)

"command! -nargs=* -complete=custom,projs#complete PrjBuildCleanup 
	"\ call projs#build#cleanup(<f-args>)

command! -nargs=* -complete=custom,projs#complete#prjbuild PrjBuild
	\ call projs#build#action(<f-args>)

command! -nargs=* -complete=custom,projs#complete#secnamesbase VSECBASE
  	\ call projs#opensec(<f-args>) 

command! -nargs=* -complete=custom,projs#complete#secnames     VSEC
  	\ call projs#opensec(<f-args>) 


