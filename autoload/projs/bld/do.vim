
function! projs#bld#do#show_trg ()
  call projs#bld#run({
      \ 'act' : 'show_trg'
      \ })

endfunction

function! projs#bld#do#pdf_view ()

  call projs#pdf#view({ 'type' : 'bld' })

endfunction

function! projs#bld#do#jnd_view ()

	let target = projs#bld#target()
	let proj = projs#proj#name()

  let jnd_tex = join([ projs#root(), 'builds', proj, 'src', target, 'jnd.tex' ],"/")
	call base#fileopen({ 
		\	'files'    : [jnd_tex],
		\	'load_buf' : 1,
		\	})

endfunction

function! projs#bld#do#view_trg ()
  let trg = projs#bld#trg#choose()

  let sec = printf('_bld.%s', trg)
  call projs#sec#open_load_buf(sec)

endfunction

function! projs#bld#do#dump_sec ()

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
