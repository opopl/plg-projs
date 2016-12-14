
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

function! projs#complete#projsload (...)
 let s  = ''
 let s .= ' tex'
 let s .= ' phd'

 let comps = base#qwsort(s)

 return join(comps,"\n")
endfunction

function! projs#complete#varlist (...)
  return projs#complete#vars([ 'varlist' ])
endfunction

function! projs#complete#buildmodes (...)
  return projs#complete#vars([ 'buildmodes' ])
endfunction

function! projs#complete#projsdirs (...)
  return projs#complete#vars([ 'projsdirs' ])
endfunction

function! projs#complete#secnamesbase (...)
  return projs#complete#vars([ 'secnamesbase' ])
endfunction

function! projs#complete#projrootsec (...)
  return projs#complete#vars([ 'latex_sectionnames' ])
endfunction

function! projs#complete#secnamesall (...)
  return projs#complete#vars([ 'secnamesall' ])
endfunction

function! projs#complete#prjgit (...)

 let comps=projs#proj#gitcmds()

 return join(comps,"\n")
endfunction

function! projs#complete#prjfiles (...)

 let s  = ''
 let s .= ' list'
 let s .= ' view'
 let acts = base#qwsort(s)

 return join(acts,"\n")
endfunction

function! projs#complete#pics (...)
   return projs#complete#vars([ 'piclist' ])
endfunction

function! projs#complete#prjbuild (...)

 let s  = ''
 	\ .	' View '
 	\ .	' Cleanup '
 	\ .	' Run '
 	\ .	' List '

 let comps=base#qwsort(s)
 return join(comps,"\n")
endfunction

function! projs#complete#prjact (...)
   return projs#complete#vars([ 'opts_PrjAct' ])
endfunction

function! projs#complete#prjinsert (...)
   return projs#complete#vars([ 'opts_PrjInsert' ])
endfunction

function! projs#complete#templates_vim (...)
	 let comps = keys(projs#varget('templates_vim',{}))
 	 return join(comps,"\n")
endfunction

function! projs#complete#templates_tex (...)
	 let comps = keys(projs#varget('templates_tex',{}))
 	 return join(comps,"\n")
endfunction

function! projs#complete#update (...)
   return projs#complete#vars([ 'opts_PrjUpdate' ])
endfunction

function! projs#complete#varlist (...)
   	let varlist = projs#varlist()
   	let comps   = varlist

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

function! projs#complete#switch (...)
  return projs#complete#vars([ 'loaded' ])
endfunction

function! projs#complete#gitcmds (...)
  let c = base#qw('cip st')
  call projs#var('gitcmds',c)
  return projs#complete#vars([ 'gitcmds' ])
endfunction
