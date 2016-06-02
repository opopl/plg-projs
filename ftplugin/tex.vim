
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

function! b:SetOpts()
	setlocal ts=2
	setlocal iminsert=0
	call projs#maps()
endfunction

" if we are dealing with a 'projs' (La)TeX file
if ( ( b:dirname == b:root ) && ( b:ext == 'tex' ) )

	let b:proj = substitute(b:basename,'^\(\w\+\)\..*','\1','g')

	if index(base#qw('inc jnames defs'),b:proj) >= 0
		finish
	endif

	if (b:proj =~ '^'.'_def')
		finish
	endif

	let b:sec = projs#secfromfile({ 
		\	"file" : b:basename ,
		\	"type" : "basename" ,
		\	"proj" : b:proj     ,
   		\	})

	let  mprg='projs_pdflatex'
	let  mprg='projs_latexmk'

	let aucmds = [ 
			\	'call projs#root("'.escape(b:root,'\').'")'           ,
			\	'StatusLine projs'                        ,
			\	'call projs#maps()'                       ,
			\	'call projs#proj#name("' . b:proj .'")'   ,
			\	'call projs#proj#secname("' . b:sec .'")' ,
			\	'call make#makeprg("'.mprg.'",{"echo":0})',
			\	'TgSet projs_this'                        ,
			\	'call b:SetOpts()'                        ,
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

