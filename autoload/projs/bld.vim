
function! projs#bld#make_secs ()

  let scs = base#varget('projs_bld_compile_secs',[])
	let o = {
			\	'git_add' : 1,
			\	}

  for s in scs
    let f = projs#sec#file(s)
    if !filereadable(f)
			call projs#sec#new(s,o)
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

function! projs#bld#jnd_tex ()
	let proj  = projs#proj#name()

  let jnd_tex = base#qw#catpath( projs#rootid(),printf('builds %s src jnd.tex',proj))
	return jnd_tex
endfunction
