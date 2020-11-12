
function! projs#bld#trg#list ()
  let bfile = projs#sec#file('_perl.bld')

  call projs#rootcd()
  let ok = base#sys({ 
    \ "cmds"         : [ printf('perl %s show_trg',bfile) ],
    \ "split_output" : 0,
    \ })
  let targets    = base#varget('sysout',[])
  return targets
  
endfunction

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

  return target

endfunction
