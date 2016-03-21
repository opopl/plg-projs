
function! projs#build#cleanup (...)
	let bfiles = projs#build#files()

	if !len(bfiles)
		echo 'No build files to remove!'
		return
	endif
	
	echohl Title
	echo 'Files to remove:'
	echohl MoreMsg
	for bfile in bfiles
		echo "\t" . bfile
	endfor
	echohl None

	let rm = input('Remove these files? (y/n):','y')
	if rm == 'y'
		echo "\n"
		for bfile in bfiles
			echo "\t" . 'Removing file: ' . bfile 
			call delete(bfile)
		endfor
	endif

endfunction

function! projs#build#files (...)
	let pdfout = projs#var('pdfout')
	let proj   = projs#proj#name()

	let bfiles = []

	" ---------------- get built PDF files
	let fref = {
		\ "dirs" : [pdfout],
		\ "pat"  : '^'.proj.'\d\+'.'\.pdf',
		\ "relpath" : 0,
		\ "subdirs" : 0,
		\ "exts" : ["pdf"],
		\ }
	let pdffiles = base#find(fref)

	call extend(bfiles,pdffiles)

	" ---------------- get all other build files
	let builddir = projs#builddir()
	let files = []

	let fref = {
		\ "dirs" : [builddir],
		\ "relpath" : 0,
		\ "subdirs" : 1,
		\ }

	let files = base#find(fref)

	call extend(bfiles,files)

	return bfiles

endfunction
