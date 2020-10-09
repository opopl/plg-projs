

function! projs#bld#run (...)
  let ref  = get(a:000,0,{})

  let act  = get(ref,'act','')
  let opts = get(ref,'opts',[])

  let proj = projs#proj#name()
  let root = projs#root()

  call projs#bld#make_secs()
  let bfile = projs#sec#file('_perl.bld')

  call chdir(root)

  let a = [ 'perl', bfile, act ]
  call extend(a,opts)

  let cmd = join(a, ' ' )

  let env = {
    \ 'proj'    : proj,
    \ 'root'    : root,
    \ 'cmd'     : cmd,
    \ 'act'     : act,
    \ }
  
  function env.get(temp_file) dict
    let temp_file = a:temp_file
    let code      = self.return_code

    let act       = self.act
    let proj      = self.proj
  
    if filereadable(a:temp_file)
      let out = readfile(a:temp_file)
      let stl_add = [
          \ '[ %3* act = '.act.' %1* proj = '.proj.' %0* ]',
          \ ]
      let cmds_after = [] 
      
      call base#buf#open_split({ 
        \  'lines'      : out,
        \  'stl_add'    : stl_add,
        \  'cmds_after' : cmds_after,
        \  })
    endif
  endfunction
  
  call asc#run({ 
    \  'cmd' : cmd, 
    \  'Fn'  : asc#tab_restore(env) 
    \  })

endf

function! projs#bld#do (...)
  let act  = get(a:000,0,'')

  let acts = base#varget('projs_opts_BLD',[])

  let proj = projs#proj#name()

  call projs#bld#make_secs()

  let fmt_sub = 'projs#bld#do#%s'
  let front = [
      \ 'Current project:' , "\t" . proj,
      \ 'Possible BLD actions: ' 
      \ ]
  let desc = base#varget('projs_desc_BLD',{})

  let Fc = projs#fc#match_proj({ 'proj' : proj })
  
  call base#util#split_acts({
    \ 'act'     : act,
    \ 'acts'    : acts,
    \ 'desc'    : desc,
    \ 'front'   : front,
    \ 'fmt_sub' : fmt_sub,
    \ 'Fc'      : Fc,
    \ })

endfunction

function! projs#bld#make_secs ()

  let scs = base#varget('projs_bld_compile_secs',[])
  let o = {
      \ 'git_add' : 0,
      \ }

  for s in scs
    let f = projs#sec#file(s)
    if !filereadable(f)
      call projs#sec#new(s,o)
    endif
  endfor
  
endfunction


function! projs#bld#target ()

  let target = projs#bld#trg#choose()
  
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
