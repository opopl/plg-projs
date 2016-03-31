
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

function! projs#complete#prjmake (...)
  return projs#complete#vars([ 'prjmake_opts' ])
endfunction

function! projs#complete#varlist (...)

  return projs#complete#vars([ 'varlist' ])
	
endfunction

function! projs#complete#secnamesbase (...)
  return projs#complete#vars([ 'secnamesbase' ])
endfunction

function! projs#complete#secnamesall (...)
  return projs#complete#vars([ 'secnamesall' ])
endfunction

function! projs#complete#prjgit (...)

 let s  = ''
 let s .= ' add'
 let s .= ' rm'

 let comps=base#qwsort(s)

 return join(comps,"\n")
endfunction

function! projs#complete#update (...)

 let s  = ''
 let s .= ' secnames'
 let s .= ' secnamesbase'

 let comps=base#qwsort(s)

 return join(comps,"\n")
endfunction

function! projs#complete#grep (...)
 let comps=base#qwsort('')

 return join(comps,"\n")

endfunction

function! projs#complete#secnames (...)

  "call projs#proj#secnames()
  return projs#complete#vars([ 'secnames' ])
	
endfunction

function! projs#complete#projsdirslist (...)

  return projs#complete#vars([ 'projsdirslist' ])
	
endfunction

function! projs#complete#gitcmds (...)
  let c = base#qw('cip st')
  call projs#var('gitcmds',c)
  return projs#complete#vars([ 'gitcmds' ])
endfunction
