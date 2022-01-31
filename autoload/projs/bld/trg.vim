
function! projs#bld#trg#list ()
  let bfile = projs#sec#file('_perl.bld')

  call projs#rootcd()

  let ok = base#sys({ 
    \ "cmds"         : [ printf('perl %s show_trg',bfile) ],
    \ "split_output" : 0,
    \ })

  let targets = base#varget('sysout',[])
  let targets = sort(targets)

  let sec_buf = projs#buf#sec()
  if len(sec_buf)
    let t_short = '_buf'
    let t_full  = projs#bld#trg#full({ 'target' : t_short })

    for trg in [ t_short, t_full ]
      if len(trg)
        call add(targets,trg)
      endif
    endfor

  endif

  let targets = sort(targets)
  let targets = base#uniq(targets)

  return targets
  
endfunction

if 0
  Usage
    let target = projs#bld#trg#full ({ 'target' : '_buf' })

  Call tree
    calls
      projs#buf#sec
    called by
endif

function! projs#bld#trg#full (...)
  let ref = get(a:000,0,{})

  let target = get(ref,'target','')

  let trg_full = target

  if target == '_buf'
    let sec_buf = projs#buf#sec()
    let trg_full = len(sec_buf) ? printf('_buf.%s',sec_buf) : ''
  endif

  return trg_full

endfunction

if 0
  Usage
    let target = projs#bld#trg#choose()

  Arguments
    None

  Call tree
    calls 
      projs#bld#trg#list
      
    called by
      projs#bld#target
        projs#action#bld_compile
          projs#action#bld_compile_xelatex
endif

function! projs#bld#trg#choose ()

  let targets = projs#bld#trg#list()
  let proj    = projs#proj#name()

  let target = ''
  if len(targets) == 1
    let target = remove(targets,0)
  else
    call base#varset('this',targets)
    while (!len(target) || !base#inlist(target,targets) )
      let target = input(printf('[%s] target: ',proj),'','custom,base#complete#this')
    endw
  endif

  let target = projs#bld#trg#full({ 'target' : target })

  call base#varset('projs_bld_target',target)

  return target

endfunction
