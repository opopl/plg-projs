
if exists("b:did_projs_tex_ftplugin")
  finish
endif
let b:did_projs_tex_ftplugin = 1

let b:file     = expand('%:p')
let b:basename = expand('%:p:t')
let b:ext      = expand('%:p:e')

let b:root    = projs#root()
let b:dirname = expand('%:p:h')

let b:finfo   = base#getfileinfo()

" if we are dealing with a 'projs' file
if b:dirname == b:root

	let b:proj = substitute(b:basename,'^\(\w\+\).*','\1','g')

	let b:sec = projs#secfromfile({ 
		\	"file" : b:basename ,
		\	"type" : "basename" ,
		\	"proj" : b:proj     ,
   		\	})

	let aucmds = [ 
			\	'StatusLine projs'                        ,
			\	'call projs#maps()'                        ,
			\	'call make#makeprg("projs_pdflatex",{"echo":0})'   ,
			\	'call projs#proj#name("' . b:proj .'")'   ,
			\	'call projs#proj#secname("' . b:sec .'")' ,
			\	'TgSet projs_this'                        ,
			\	] 

	let fr = '  autocmd BufWinEnter,BufRead,BufEnter,BufWritePost '
	
	let b:ufile = base#file#win2unix(b:file)
	
	exe 'augroup projs_p_' . b:proj . '_' . b:sec
	exe '  au!'
	for cmd in aucmds
		exe join([ fr,b:ufile,cmd ],' ')
	endfor
	exe 'augroup end'
endif

