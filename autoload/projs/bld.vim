
function! projs#bld#make_secs ()

  let scs = base#varget('projs_bld_compile_secs',[])
  for s in scs
		echo s
    let f = projs#sec#file(s)
    if !filereadable(f)
      call projs#sec#new(s)
    endif
  endfor
	
endfunction

function! projs#bld#target ()

	call projs#rootcd()

	let proj  = projs#proj#name()
  let bfile = projs#sec#file('_perl.bld')

  let ok = base#sys({ 
    \ "cmds"         : [ printf('perl %s show_trg',bfile) ],
    \ "split_output" : 0,
    \ })
  let targets    = base#varget('sysout',[])
  let target = ''
  if len(targets) == 1
    let target = remove(targets,0)
  else
    call base#varset('this',targets)
    while !len(target)
      let target = input(printf('[%s] target: ',proj),'','custom,base#complete#this')
    endw
  endif

	return target

endfunction

function! projs#bld#jnd_pdf ()

	let proj  = projs#proj#name()

  let jnd_pdf = base#qw#catpath( projs#rootid(),printf('builds %s src jnd.pdf',proj))
	return jnd_pdf
endfunction
