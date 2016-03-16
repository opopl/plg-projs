
if exists("b:did_projs_tex_ftplugin")
  finish
endif
let b:did_projs_tex_ftplugin = 1

let b:file = expand('%:p')
let b:dirname = expand('%:p:h')
let b:basename = expand('%:p:t')

let b:root = projs#root()

function! b:BufProcess ()
	StatusLine projs
endfunction

if b:dirname == b:root
	exe 'autocmd BufWinEnter,BufRead ' . b:file . ' call b:BufProcess() '
endif

"StatusLine projs


