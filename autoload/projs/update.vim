
function! projs#update#datvars (...)
   call base#plg#loadvars('projs')
endfunction

function! projs#update#usedpacks (...)
	let proj = projs#proj#name()

	let secs = base#qw('preamble')

	for sec in secs
		let lines = projs#filejoinlines({ 'sec' : sec })
	endfor

	let pats={
		\ 'up'  : '^\\usepackage{\(\w\+\)}'            ,
		\ 'upo' : '^\\usepackage\[\(.*\)\]{\(\w\+\)}$' ,
		\	}

	let usedpacks=[]
	let packopts={}

	for line  in lines
		if line =~ pats.up
			let pack = substitute(line,pats.up,'\1','g')

			call add(usedpacks,pack)
			call extend(packopts,{ pack : ""})

		elseif line =~ pats.upo
			let pack = substitute(line,pats.upo,'\2','g')
			let popts = substitute(line,pats.upo,'\1','g')

			call add(usedpacks,pack)
			call extend(packopts,{ pack : popts })
		endif
	endfor

	call projs#varset('usedpacks',usedpacks)
	call projs#varset('packopts',packopts)

	call projs#update('varlist')

endfunction

function! projs#update#varlist ()

		let bvars   = copy(base#varlist())
		let varlist = filter(bvars,"v:val =~ '^projs_'")
		let varlist = base#mapsub(varlist,'^projs_','','g')

    call projs#varset('varlist',varlist)
	
endfunction

function! projs#update#texfiles ()
	let proj = projs#proj#name()

  let texfiles={}
  let secnamesbase = projs#varget('secnamesbase',[])
    
  for id in secnamesbase
    let texfiles[id]=id
  endfor

  call map(texfiles, "proj . '.' . v:key . '.tex' ")
  call extend(texfiles, { '_main_' : proj . '.tex' } )

	call projs#varset('texfiles',texfiles)

	return texfiles
	
endfunction
