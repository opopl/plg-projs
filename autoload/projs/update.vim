
function! projs#update#datvars (...)

    let datvars=''
    let datvars.=" secnamesbase "
    let datvars.=" projecttypes projectstructures "
    let datvars.=" projsdirs "
    let datvars.=" prjmake_opts "
    let datvars.=" latex_sectionnames "
    let datvars.=" opts_PrjUpdate"

    let e={
        \   "root"           : base#path('projs') ,
        \   "varsfromdat"    : base#qw(datvars)   ,
        \   "extensions_tex" : base#qw('tex')     ,
        \   }

    if exists("s:projvars")
        call extend(s:projvars,e)
    else
        let s:projvars=e
    endif

    for v in projs#var('varsfromdat')
        call projs#varsetfromdat(v)
    endfor

    call projs#varsetfromdat('vars','Dictionary')

    let vars =  projs#var('vars')
    for [k,v] in items(vars)
        call projs#var(k,v)
    endfor
	
endfunction
