
function! projs#action#thisproj_cd_src (...)

	let proj = projs#proj#name()
	let root = projs#root()
	let dir  = base#file#catfile([ root,'src',proj ])

	if !isdirectory(dir)
		return
	endif

	call base#cd(dir)
endf

"""PrjAct_thisprojs_newfile

function! projs#action#thisproj_newfile (...)
	let proj  = projs#proj#name()

	let name = input('Filename:','')
	let ext  = input('Extension:','')
	let dot = '.'

	let file = join([proj,name,ext],dot)

	echo 'File to be created: ' . file

	let fpath = projs#path([ file ])

	call base#fileopen({ 'files' : [fpath] })

endfunction

function! projs#action#preamble_add_centered_toc (...)
	let t = base#qw#catpath('plg','projs data tex makeatother centered_toc.tex')
	let l = base#file#lines(f)

endfunction

"""PrjAct_thisprojs_tags_replace

function! projs#action#thisproj_tags_replace (...)
	let proj  = projs#proj#name()

	let ref_def = { 'proj' : proj }
	let ref_a   = get(a:000,0,{})
	let ref     = ref_def

	call extend(ref,ref_a)

	let proj = get(ref,'proj',proj)
	
	let files = projs#proj#files({ 'proj' : proj })
	let pdir  = projs#root()

	for f in files
		let p = base#file#catfile([ pdir, f ])
		if !filereadable(p)
			continue
		endif
		echo p

		let lines  = readfile(p)
		let nlines = []

		let pat    = '^%%file\s\+f_\(.*\)$'

		for l in lines
			if l =~ pat
				let l = substitute(l,pat,'%%file \1','g')
			endif
			call add(nlines,l)
		endfor

		call writefile(nlines,p)
	endfor

endfunction

"""PrjAct_thisproj_saveas
function! projs#action#thisproj_saveas (...)
	let proj  = projs#proj#name()

	let ref_def = { 'proj' : proj }
	let ref     = get(a:000,0,ref_def)

	let proj  = get(ref,'proj',proj)

	let files = projs#proj#files({ 'proj' : proj })
	let pdir  = projs#root()

endfunction

function! projs#action#projs_tags_replace ()
	let list = projs#varget('list',[])

	let oldproj=projs#proj#name()

	for proj in list
		call projs#action#thisproj_tags_replace({ 'proj': proj})
	endfor

endfunction

function! projs#action#buildmode_set ()
	let buildmode=input('PROJS buildmode:','','custom,projs#complete#buildmodes')
	
	call projs#varset('buildmode',buildmode)
	call projs#echo('Build mode set: ' . buildmode)

endfunction
