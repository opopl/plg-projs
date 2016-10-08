
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

function! projs#action#thisproj_saveas (...)
	let proj  = projs#proj#name()

	let ref_def = { 'proj' : proj }
	let ref     = get(a:000,0,ref_def)

	let proj = get(ref,'proj',proj)
	
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
