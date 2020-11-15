
function! projs#bld#run_Fc (self, temp_file)
    let temp_file = a:temp_file
    let self      = a:self

    let code      = self.return_code

    let act       = self.act
    let proj      = self.proj

    let stl       = get(self,'stl',[])
  
    if !filereadable(a:temp_file)
      return
    endif

    let out = readfile(a:temp_file)
    let stl_add = [
        \ '[ %3* act = '.act.' %1* proj = '.proj.' %0* ]',
        \ ]
    call extend(stl_add,stl)
    let cmds_after = [] 
    
    call base#buf#open_split({ 
      \  'lines'      : out,
      \  'stl_add'    : stl_add,
      \  'cmds_after' : cmds_after,
      \  })

endfunction

function! projs#bld#input_path (...)
  let ref = get(a:000,0,{})

  let hist_name = get(ref,'hist','projs_bld_dump_paths')

  let proj   = projs#proj#name()
  let rootid = projs#rootid()

  let msg_a = [
    \  "proj:   " . proj,  
    \  "rootid: " . rootid,  
    \  ' ',
    \  '[dump_bld] path: ',
    \  ]
  let msg = join(msg_a,"\n")

  let path = base#input_hist(msg,'',hist_name)

  return path

endf

function! projs#bld#run (...)
  let ref  = get(a:000,0,{})

  let act  = get(ref,'act','')
  let opts = get(ref,'opts',[])

  let stl  = get(ref,'stl',[])

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
    \ 'stl'     : stl,
    \ }
  
  function env.get(temp_file) dict
    call projs#bld#run_Fc(self,a:temp_file)
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

function! projs#bld#jnd_pdf (...)
  let ref = get(a:000,0,{})

  let target = base#varget('projs_bld_target','')
  let target = get(ref,'target',target)

  let proj  = projs#proj#name()

  let jnd_pdf = base#qw#catpath( projs#rootid(),printf('builds %s src %s jnd.pdf',proj,target))
  return jnd_pdf
endfunction

function! projs#bld#jnd_tex (...)
  let ref = get(a:000,0,{})

  let proj  = projs#proj#name()

  let target = base#varget('projs_bld_target','')
  let target = get(ref,'target',target)

  let jnd_tex = base#qw#catpath( projs#rootid(),printf('builds %s src %s jnd.tex',proj,target))
  return jnd_tex
endfunction
