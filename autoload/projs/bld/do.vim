
function! projs#bld#do#show_trg ()
  call projs#bld#run({
      \ 'act' : 'show_trg'
      \ })

endfunction

function! projs#bld#do#pdf_view ()

  call projs#pdf#view()

endfunction

function! projs#bld#do#view_trg ()

function! projs#bld#do#dump_bld ()
  let proj   = projs#proj#name()
  let rootid = projs#rootid()

  let msg_a = [
    \  "proj:   " . proj,  
    \  "rootid: " . rootid,  
    \  ' ',
    \  '[dump_bld] path: ',
    \  ]
  let msg = join(msg_a,"\n")
  let path = base#input(msg,'',{ })

  let opts = []
  if len(path)
    call extend(opts,[ '-d', shellescape(path) ])
  endif

  call projs#bld#run({
      \ 'act'  : 'dump_bld',
      \ 'opts' : opts,
      \ })

endfunction
