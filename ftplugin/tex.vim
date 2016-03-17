
if exists("b:did_projs_tex_ftplugin")
  finish
endif
let b:did_projs_tex_ftplugin = 1

function! b:BufProcess ()
	StatusLine projs
endfunction

let b:file     = expand('%:p')
let b:dirname  = expand('%:p:h')
let b:basename = expand('%:p:t')
let b:ext      = expand('%:p:e')

let b:root = projs#root()
let b:proj = substitute(b:basename,'^\(\w\+\).*','\1','g')

if b:ext == 'tex'
	if b:basename =~ '\.\(\w\+\)\.tex$'
		let b:sec = substitute(b:basename,'^.*\.\(\w\+\)\.tex$','\1','g')
	elseif b:basename == b:proj . '.tex' 
		let b:sec = '_main_'
	endif
endif

let b:fi=base#getfileinfo()

call b:BufProcess()

if b:dirname == b:root
  exe 'augroup projs_p_' . b:proj . '_' . b:sec
  exe '  au!'
  exe '  autocmd BufWinEnter,BufRead,BufEnter,BufWritePost ' . b:file . ' call b:BufProcess() '
  exe 'augroup end'
endif

"StatusLine projs


