
function! projs#update#datvars (...)
   call base#plg#loadvars('projs')
endfunction

function! projs#update#usedpacks (...)
  let proj = projs#proj#name()

  let secs = base#qw('preamble')

  for sec in secs
    let lines = projs#filejoinlines({ 'sec' : sec })
  endfor

  "upm - multiple lines
  "up  - single line, without options
  "upo - single line, with options
  
  let pats={
    \ 'up'        : '^\\usepackage\s*{\(\w\+\)}\s*'               ,
    \ 'upm_start' : '^\\usepackage\s*\['                    ,
    \ 'upm_end'   : '\]{\(\w\+\)}\s*$'                    ,
    \ 'upo'       : '^\\usepackage\s*\[\(.*\)\]\s*{\(\w\+\)}\s*$' ,
    \ 'dc'        : '^\\documentclass\s*{\(\w\+\)}\s*$' ,
    \ 'dco'       : '^\\documentclass\[\(.*\)\]\s*{\(\w\+\)}\s*$' ,
    \ }

  let usedpacks = []
  let packopts  = {}
  let mode      = {}
  let popts     = ''

  " documentclass
  let dc  = ''
  let dco = ''

  while len(lines)
    let line=remove(lines,0)

    while 1
      if len(lines) && get(mode,'insideopt',0)
        let line=remove(lines,0)
        while 1
          if line =~ pats.upm_end
            let pack=substitute(line,pats.upm_end,'\1','g')
            let mode['insideopt']=0

            let popts=base#rmwh(popts)

            call add(usedpacks,pack)
            call extend(packopts,{ pack : popts })

            break
          endif
          if !len(lines)
            break
          endif
          let popts.=line
          let line=remove(lines,0)
        endw
        break
      endif

      if line =~ pats.up
        let pack = substitute(line,pats.up,'\1','g')
  
        call add(usedpacks,pack)
        call extend(packopts,{ pack : ""})
  
      elseif line =~ pats.upo
        let pack  = substitute(line,pats.upo,'\2','g')
        let popts = substitute(line,pats.upo,'\1','g')
  
        call add(usedpacks,pack)
        call extend(packopts,{ pack : popts })
  
      elseif line =~ pats.upm_start
        let mode['insideopt']=1
        let popts=''

      elseif line =~ pats.dc
        let dc  = substitute(line,pats.dc,'\1','g')

      elseif line =~ pats.dco
        let dco  = substitute(line,pats.dco,'\1','g')
        let dc   = substitute(line,pats.dco,'\2','g')

      endif
      break
    endw
  endw

  call projs#varset('usedpacks',usedpacks)
  call projs#varset('packopts',packopts)
  call projs#varset('dc',dc)
  call projs#varset('dco',dco)

  let pdir_id    = projs#rootid()

  let pdata          = base#varget('prjdata',{})
  let pdata_pdir     = get(pdata,pdir_id,{})
  let pdata_projdata = get(pdata_pdir,'projdata',{})

  let pdata_proj = get(pdata_pdir,proj,{})
  call extend(pdata_proj,{
    \ 'usedpacks' : usedpacks,
    \ 'packopts'  : packopts,
    \ 'dc'        : dc,
    \ 'dco'       : dco,
    \ })
  call extend(pdata_projdata,{ proj : pdata_proj })
  call extend(pdata_pdir,{ 'projdata' : pdata_projdata })
  call extend(pdata, { pdir_id : pdata_pdir })

  call base#varset('prjdata',pdata)

  call projs#update('varlist')

endfunction

if 0
  call tree
    calls
      base#varlist
      base#mapsub
      projs#varset
    called by
      projs#init
endif

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
