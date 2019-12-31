
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
    call extend(comps,projs#varget(varname,[]))
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

fun! projs#complete#htlatex (...)
  return projs#complete#vars([ 'opts_PrjHTLATEX' ])
endfunction

function! projs#complete#hist_grep (...)
  let hist = base#varref('projs_hist_grep',[])
  let hist = base#uniq(hist)
  let hist = sort(hist)

  let comps = []
  call extend(comps,hist)
  return join(comps,"\n")
endfunction

function! projs#complete#buildmodes (...)
  return projs#complete#vars([ 'buildmodes' ])
endfunction

function! projs#complete#projsdirs (...)
  return projs#complete#vars([ 'projsdirs' ])
endfunction



function! projs#complete#projrootsec (...)
  return projs#complete#vars([ 'latex_sectionnames' ])
endfunction

function! projs#complete#prjgit (...)
 let comps = projs#proj#gitcmds()

 return join(comps,"\n")
endfunction

function! projs#complete#pics (...)
   return projs#complete#vars([ 'piclist' ])
endfunction

function! projs#complete#prjfiles (...)
   return projs#complete#vars([ 'opts_PrjFiles' ])
endfunction

function! projs#complete#prjbuild (...)
   return projs#complete#vars([ 'opts_PrjBuild' ])
endfunction

function! projs#complete#prjact (...)
   return projs#complete#vars([ 'opts_PrjAct' ])
endfunction

function! projs#complete#prjtab (...)
   return projs#complete#vars([ 'opts_PrjTab' ])
endfunction

function! projs#complete#prjgui (...)
   return projs#complete#vars([ 'opts_PrjGui' ])
endfunction

function! projs#complete#prjbuf (...)
   return projs#complete#vars([ 'opts_PrjBuf' ])
endfunction

if 0
	echo projs#complete#db_tags('doctrine')
endif

function! projs#complete#db_tags (...)
  let arg  = get(a:000,0,'')
  let line = get(a:000,1,'')
  let pos  = get(a:000,2,'')

  let tags = projs#db#tags_get()

  let comps = []

	if !strlen(arg)
		call extend(comps,tags)
	else

  	let parts = split(arg, ',')
		call map(parts,'base#trim(v:val)')

		while len(parts)
			let last = remove(parts,-1)
			let prev = join(parts, ',')
	
			if strlen(prev)
				call extend(comps,map( copy(tags), printf('"%s," . v:val',prev) ))
			else
				call extend(comps,tags)
			endif
		endw
	endif

  return join(comps,"\n")
endfunction

function! projs#complete#prjdb (...)
   return projs#complete#vars([ 'opts_PrjDB' ])
endfunction

function! projs#complete#prjvisual (...)
   return projs#complete#vars([ 'opts_PrjVisual' ])
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
  let comps = []

  call extend(comps,projs#db#secnames())
  call extend(comps,base#varget('projs_secnamesbase',[]))

  return join(comps,"\n") 
endfunction

function! projs#complete#secnamesbase (...)
  return projs#complete#vars([ 'secnamesbase' ])
endfunction

function! projs#complete#secnamesall (...)
  let secnamesall=[]
  call projs#proj#secnamesall()
  return projs#complete#vars([ 'secnamesall' ])
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
