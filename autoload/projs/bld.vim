

function! projs#bld#do (...)
  let act = get(a:000,0,'')

  let acts = base#varget('projs_opts_BLD',[])
  let acts = sort(acts)
  if ! strlen(act)
    let desc = base#varget('projs_desc_BLD',{})
    let info = []
    for act in acts
      call add(info,[ act, get(desc,act,'') ])
    endfor
    let proj = projs#proj#name()
    let lines = [ 
      \ 'Current project:' , "\t" . proj,
      \ 'Possible BLD actions: ' 
      \ ]

    call extend(lines, pymy#data#tabulate({
      \ 'data'    : info,
      \ 'headers' : [ 'act', 'description' ],
      \ }))

    let s:obj = { 'proj' : proj }
    function! s:obj.init (...) dict
      let proj = self.proj
      let hl = 'WildMenu'
      call matchadd(hl,'\s\+'.proj.'\s\+')
      call matchadd(hl,proj)
    endfunction
    
    let Fc = s:obj.init

    call base#buf#open_split({ 
      \ 'lines'    : lines ,
      \ 'cmds_pre' : ['resize 99'] ,
      \ 'Fc'       : Fc,
      \ })
    return
  endif

  let sub = printf('projs#bld#do#%s', act)

  exe printf('call %s()',sub)

endfunction

function! projs#bld#make_secs ()

  let scs = base#varget('projs_bld_compile_secs',[])
  let o = {
      \ 'git_add' : 1,
      \ }

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
