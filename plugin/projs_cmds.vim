

command! -nargs=* -complete=custom,projs#complete            PV
	\ call projs#viewproj(<f-args>) 

command! -nargs=* -complete=custom,projs#complete            PN
	\ call projs#new(<f-args>) 

"command! -nargs=* -complete=custom,projs#complete#projsdirslist
command! -nargs=* -complete=custom,base#complete#CD          ProjsInit
	\ call projs#init(<f-args>)

command! -nargs=* -complete=custom,projs#complete#varlist    ProjsVarEcho 
	\ call projs#varecho(<f-args>)

command! -nargs=* -complete=custom,projs#complete#gitcmds    ProjsGit
	\ call projs#git(<f-args>)

command! -nargs=* -complete=custom,projs#complete#projsload  ProjsLoad
	\ call projs#load(<f-args>)

command! -nargs=* -complete=custom,projs#complete            PrjView
	\ call projs#viewproj(<f-args>) 

command! -nargs=* -complete=custom,projs#complete            PrjNew
	\ call projs#new(<f-args>) 

command! -nargs=* -complete=custom,projs#complete            PrjPdfView
	\ call projs#pdf#view(<f-args>) 

command! -nargs=* -complete=custom,projs#complete#prjmake    PrjMake
 	\ call projs#prjmake(<f-args>)

command! -nargs=* -complete=custom,projs#complete#prjmake    PrjMakePrompt
 	\ call projs#prjmakeprompt(<f-args>)

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

command! -nargs=* -complete=custom,projs#complete#varlist    PrjVarEcho
	\ call projs#varecho(<f-args>)

command! -nargs=* -complete=custom,projs#complete#secnamesall PrjSecNew
	\ call projs#newsecfile(<f-args>,{ "view" : 1 })

command! -nargs=* -complete=custom,projs#complete#secnames PrjSecRename
	\ call projs#sec#rename(<f-args>)

command! -nargs=* -complete=custom,projs#complete#secnames PrjSecRemove
	\ call projs#sec#remove(<f-args>)

command! -nargs=* -complete=custom,projs#complete#defs     PrjDefShow
	\ call projs#def#show(<f-args>) 

command! -nargs=*             PrjDefNew
	\ call projs#def#new(<f-args>) 

command! -nargs=* -complete=custom,projs#complete#prjfiles PrjFiles
	\	call projs#proj#filesact(<f-args>)

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

command! -nargs=* -complete=custom,projs#complete#switch PrjSwitch
	\ call projs#switch(<f-args>)

command! -nargs=* -complete=custom,projs#complete#secnamesbase VSECBASE
  	\ call projs#opensec(<f-args>) 

command! -nargs=* -complete=custom,projs#complete#secnames     VSEC
  	\ call projs#opensec(<f-args>) 

command! -nargs=0 CitnTexToDat call s:CitnTexToDat()
command! -nargs=0 CitnDatToTex call s:CitnDatToTex()
command! -nargs=0 CitnDatView  call s:CitnDatView()

function! s:CitnDatView ()
	let proj = projs#proj#name()
	let datf  = projs#path([proj . '.citn.i.dat' ])

	call base#fileopen({ "files" : [ datf ] })
endf

function! s:CitnTexToDat ()
	let proj = projs#proj#name()
	let texf = projs#secfile('citn')

	if !filereadable(texf)
		return
	endif

	let datf  = projs#path([proj . '.citn.i.dat' ])
	let lines = readfile(texf)

	let pat = '^\s*\\ifthenelse{\\equal{#1}{\(\d\+\)}}{\\cite{\(.*\)}}{}.*$'

	let datlines=[]

	for line in lines
		if line =~ pat
			let num = substitute(line,pat,'\1','g')
			let key = substitute(line,pat,'\2','g')
			let nline = num . ' ' .key
			call add(datlines,nline)
		endif
	endfor

	echo 'Writing citn.i.dat file:'
	echo ' ' . datf

	call writefile(datlines,datf)

endfunction

function! s:CitnDatToTex ()
	let proj = projs#proj#name()

	let datf  = projs#path([proj . '.citn.i.dat' ])

	if !filereadable(datf)
		return
	endif

	let texf = projs#secfile('citn')

	let texlines=[]
	call add(texlines,' ')
	call add(texlines,'%%file f_citn')
	call add(texlines,' ')
	call add(texlines,'\def\citn#1{%')

	let lines = readfile(datf)

	let pat ='^\(\d\+\)\s\+\(.*\)$'
	for line in lines
		if line =~ pat
			let num = substitute(line,pat,'\1','g')
			let key = substitute(line,pat,'\2','g')
			let x  = '  \ifthenelse{\equal{#1}{'.num.'}}{\cite{'.key.'}}{}%'
			call add(texlines,x)
		endif
	endfor

	call add(texlines,'}')

	echo 'Writing citn.tex file:'
	echo ' ' . texf

	call writefile(texlines,texf)

endfunction


