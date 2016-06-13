
function! projs#update#datvars (...)
   call base#plg#loadvars('projs')
endfunction

function! projs#update#varlist ()

		let bvars   = copy(base#varlist())
		let varlist = filter(bvars,"v:val =~ '^projs_'")
		let varlist = base#mapsub(varlist,'^projs_','','g')

    call projs#varset('varlist',varlist)
	
endfunction

function! projs#update#texfiles ()

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
