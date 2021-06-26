
function! projs#bld#run_Fc (self, temp_file)
    let temp_file = a:temp_file
    let self      = a:self

    let code      = self.return_code

    let act           = self.act
    let proj          = self.proj

    let skip_split = get(self,'skip_split',0)

    let Fc      = get(self,'Fc','')
    let Fc_args = get(self,'Fc_args',[])

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

    if ! skip_split
      call base#buf#open_split({ 
        \  'lines'      : out,
        \  'stl_add'    : stl_add,
        \  'cmds_after' : cmds_after,
        \  })
    endif

    if type(Fc) == type(function('call'))
      call call(Fc,Fc_args)
    endif

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

""cmt
if 0
  call tree
    called by
      projs#bld#do#print_ii_tree
endif
""endcmt

function! projs#bld#run (...)
  let ref  = get(a:000,0,{})

  let act  = get(ref,'act','')
  let opts = get(ref,'opts',[])

  let stl  = get(ref,'stl',[])

  let Fc  = get(ref,'Fc','')

  let skip_split  = get(ref,'skip_split',0)

  let proj = projs#proj#name()
  let root = projs#root()

  call projs#bld#make_secs()
  let bfile = projs#sec#file('_perl.bld')

  call chdir(root)

  let a = [ 'perl', bfile, act ]
  call extend(a,opts)

  let cmd = join(a, ' ' )

  let s:obj = { 'proj' : proj }
  function! s:obj.init (...) dict
    let proj = get(self,'proj','')
    call base#rdw(printf('[proj: %s, rootid: %s] print_ii_tree', proj, projs#rootid() ))
  endfunction
  
  let Fc = s:obj.init

  let env = {
    \ 'proj'       : proj,
    \ 'root'       : root,
    \ 'cmd'        : cmd,
    \ 'act'        : act,
    \ 'stl'        : stl,
    \ 'skip_split' : skip_split,
    \ 'Fc'         : Fc,
    \ }
  
  function env.get(temp_file) dict
    call projs#bld#run_Fc(self,a:temp_file)
  endfunction
  
  call asc#run({ 
    \  'cmd' : cmd, 
    \  'Fn'  : asc#tab_restore(env) 
    \  })

endf

if 0
  call tree
    calls 
      projs#proj#name
      projs#bld#make_secs
      projs#fc#match_proj
      base#util#split_acts
endif

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

if 0
  Usage
    let target = projs#bld#target()

  Call tree
    called by
      projs#action#bld_compile
    calls
      projs#bld#trg#choose
        projs#bld#trg#list
endif

function! projs#bld#target (...)
  let ref = get(a:000,0,{})

  let target = get(ref,'target','')
  if !len(target)
    let target = projs#bld#trg#choose()
  endif
  
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
