
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

function! projs#bld#do#pdf_view ()

  call projs#pdf#view({ 'type' : 'bld' })

endfunction

if 0
  call tree
    calls
      projs#bld#target
        projs#bld#trg#choose
          projs#bld#trg#list
endif

function! projs#bld#do#jnd_view ()

  let target  = projs#bld#target()
  let proj    = projs#proj#name()

  let jnd_tex = join([ projs#root(), 'builds', proj, 'src', target, 'jnd.tex' ],"/")
  call base#fileopen({ 
    \ 'files'    : [jnd_tex],
    \ 'load_buf' : 1,
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
