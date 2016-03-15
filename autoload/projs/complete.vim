
function! projs#complete#vars (...)

 let comps=[]

 if a:0
   if type(a:1) == type([])
     let vars=a:1

   elseif type(a:1) == type('')
     let vars=[ a:1 ] 

   endif
 endif

  for varname in vars
    call extend(comps,projs#var(varname))
  endfor

 let comps=base#uniq(sort(comps))

 return join(comps,"\n")
 
endfunction

function! projs#complete#varlist (...)

  return projs#complete#vars([ 'varlist' ])
	
endfunction

function! projs#complete#secnamesbase (...)

  return projs#complete#vars([ 'secnamesbase' ])
	
endfunction

function! projs#complete#secnames (...)

  return projs#complete#vars([ 'secnames' ])
	
endfunction
