
function! projs#bld#do#show_trg ()
  call projs#bld#run({
      \ 'act' : 'show_trg'
      \ })

endfunction

function! projs#bld#do#pdf_view ()

  call projs#pdf#view({ 'type' : 'bld' })

endfunction

function! projs#bld#do#jnd_view ()
  let sec = printf('_tex_jnd_')
  call projs#sec#open_load_buf(sec)

endfunction

function! projs#bld#do#view_trg ()
  let trg = projs#bld#trg#choose()

  let sec = printf('_bld.%s', trg)
  call projs#sec#open_load_buf(sec)

endfunction

function! projs#bld#do#dump_sec ()

endfunction

function! projs#bld#do#dump ()
  let proj   = projs#proj#name()
  let rootid = projs#rootid()

  let msg_a = [
    \  "proj:   " . proj,  
    \  "rootid: " . rootid,  
    \  ' ',
    \  '[dump_bld] path: ',
    \  ]
  let msg = join(msg_a,"\n")

  let plist = 'projs_bld_dump_paths'

  let paths = base#varget(plist,[])
  call base#varset('this',paths)

  let path = base#input(msg,'',{ 'complete' : 'custom,base#complete#this' })

  call add(paths,path)
  let paths = base#uniq(paths)
  call base#varset(plist,paths)

  call projs#bld#run#dump_path({
    \ 'path' : path
    \ })


endfunction

function! projs#bld#do#core_dump ()

endfunction

function! projs#bld#do#trg_dump ()
  let proj   = projs#proj#name()
  let rootid = projs#rootid()

  let trg_list = projs#bld#trg#list()

  let trg = projs#bld#trg#choose()


endfunction
