
function! s:ThisProj (...)
	let aa  = a:000
	let opt = get(aa,0,'')

	let fn="s:ThisProj_".opt
	if exists('*'.fn)
		exe 'call '.fn.'()'
	endif

endfunction

function! s:CompleteThisProj (...)
 let proj = projs#proj#name()
 let opts = projs#varget('opts_ThisProj',[])

 let f    = projs#path([ proj.'.opts_ThisProj.i.dat' ])
 if !filereadable(f)
		return ''
 endif

 let opts = base#readarr(file,{ "sort" : 1 })
 call projs#varset('opts_ThisProj',opts)

 return join(comps,"\n")

endfunction

function! s:ThisProj_Build (...)

endfunction

function! s:ThisProj_Help (...)

endfunction
