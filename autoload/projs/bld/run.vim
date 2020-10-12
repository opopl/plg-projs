
function! projs#bld#run#dump_path (...)
	let ref = get(a:000,0,{})

	let path = get(ref,'path','')

  let opts = []
  if len(path)
    call extend(opts,[ '-d', shellescape(path) ])
  endif

  call projs#bld#run({
      \ 'act'  : 'dump_bld',
      \ 'opts' : opts,
      \ })
	
endf
