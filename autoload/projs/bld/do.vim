
function! projs#bld#do#show_trg ()
  "call projs#bld#run({
      "\ 'act' : 'show_trg'
      "\ })
  let targets = projs#bld#trg#list()
  call base#buf#open_split({ 'lines' : targets })

endfunction

if 0
  call tree
    calls
      projs#pdf#view
endif

function! projs#bld#do#pdf_view (...)
  let ref = get(a:000,0,{})

  let r = { 'type' : 'bld' }
  call extend(r,ref)

  call projs#pdf#view(r)

endfunction

if 0
  call tree
    calls
      projs#bld#target
        projs#bld#trg#choose
          projs#bld#trg#list
endif

function! projs#bld#do#jnd_view (...)
  let ref = get(a:000,0,{})

  let target     = base#x#get(ref,'target','')

  call base#varset('this',base#qw('html pdf'))
  let target_ext = base#x#get(ref,'target_ext','')
  if !len(target_ext)
    let target_ext = base#input('target_ext: ','',{ 'complete' : 'custom,base#complete#this' })
  endif

  if !len(target)
    let target = projs#bld#target()
  else
    let target = projs#bld#trg#full({ 'target' : target })
  endif

  let proj    = projs#proj#name()

  "let jnd_tex = join([ projs#root(), 'builds', proj, 'src', target, 'jnd.tex' ],"/")
  let jnd_tex = projs#bld#jnd#tex({
      \ 'proj'       : proj,
      \ 'target'     : target,
      \ 'target_ext' : target_ext
      \ })

  let i = 0
  " wait for 10 secs
  let imax = 100
  let jcall = 0
  while 1
    if !filereadable(jnd_tex)
      if !jcall
        call projs#action#bld_join({
          \ 'proj'       : proj,
          \ 'target'     : target,
          \ 'target_ext' : target_ext,
          \ })
        let jcall = 1
      endif

      let i += 1
      if i == imax | break | endif
      sleep 100m

      continue
    else
      call base#fileopen({
        \ 'files'    : [jnd_tex],
        \ 'load_buf' : 1,
        \ })
    endif

    break
  endw

endfunction

function! projs#bld#do#trg_new (...)

  let targets = projs#bld#trg#list()
  let proj    = projs#proj#name()

  call base#varset('this',targets)

  let target = ''
  while (!len(target) || base#inlist(target,targets))
    let target = input(printf('[%s] new target name: ',proj),'','custom,base#complete#this')
  endw
  let tfile = projs#bld#trg#file(target)

  let trg_import = ''
  while (!len(trg_import) || !base#inlist(trg_import,targets))
    let trg_import = input(printf('[%s] import: ',proj),'','custom,base#complete#this')
  endw
  let tfile_import = projs#bld#trg#file(trg_import)
  if !filereadable(tfile_import)
    call base#rdwe('import file does not exist! abort')
    return
  endif

  let args = [ {
    \ 'proj'       : proj,
    \ 'target'     : target,
    \ 'trg_import' : trg_import,
    \ } ]

  let s:obj = { 'tfile' : tfile }
  function! s:obj.init (...) dict
    let tfile = get(self,'tfile','')
    if !filereadable(tfile)
      return
    endif

    call base#fileopen({
      \  'files'    : [tfile],
      \  'load_buf' : 1,
      \  })
  endfunction

  let Fc_done = s:obj.init

  call lts#py#act({
    \ 'act'          : 'trg_new',
    \ 'args'         : args,
    \ 'Fc_done'      : Fc_done,
    \ 'Fc_done_args' : [],
    \ })

endfunction

function! projs#bld#do#view_trg ()
  let trg = projs#bld#trg#choose()

  let sec = printf('_bld.%s', trg)
  call projs#sec#open_load_buf(sec)

endfunction

function! projs#bld#do#dump_sec ()

endfunction

function! projs#bld#do#last_compile ()
  let last = base#varget('projs_bld_last_compile',{})

  let config = get(last,'config','')
  let target = base#varget('projs_bld_target','')

  call projs#action#bld_compile({
    \ 'config' : config,
    \ 'target' : target,
    \ })

endfunction

if 0
  Usage
    call projs#bld#do#print_ii_tree ()
    call projs#bld#do#print_ii_tree ({ 'target' : 'usual' })

  Call tree
    calls
      projs#bld#target
      projs#bld#run
endif

function! projs#bld#do#print_ii_tree (...)
  let ref = get(a:000,0,{})

  let opts = []

  let target = get(ref,'target','')

  if !len(target)
    let target = projs#bld#target()
  endif
  if len(target)
    call extend(opts,[ '-t', target ])
  endif

  call projs#bld#run({
      \ 'act'        : 'print_ii_tree',
      \ 'opts'       : opts,
      \ 'skip_split' : 1,
      \ })

endfunction

function! projs#bld#do#dump ()

  let path = projs#bld#input_path()

  call projs#bld#run#dump_path({
    \ 'path' : path,
    \ })

endfunction

function! projs#bld#do#core_dump ()

  let path = projs#bld#input_path({
    \ 'hist_name' : 'projs_bld_dump_core'
    \ })

  let path = printf('targets core %s',path)
  call projs#bld#run#dump_path({
    \ 'path' : path
    \ })


endfunction

function! projs#bld#do#trg_dump ()
  let proj   = projs#proj#name()
  let rootid = projs#rootid()

  let trg_list = projs#bld#trg#list()

  let trg = projs#bld#trg#choose()


endfunction
