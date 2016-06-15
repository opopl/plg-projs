
if exists("b:did_projs_bib_ftplugin")
  finish
endif
let b:did_projs_bib_ftplugin = 1

let b:root    = projs#root()
call base#buf#start()

" if we are dealing with a 'projs' BibTeX file
if ( b:dirname == b:root )

	let b:proj = substitute(b:basename,'^\(\w\+\)\..*','\1','g')

	let b:sec = projs#secfromfile({ 
		\	"file" : b:basename ,
		\	"type" : "basename" ,
		\	"proj" : b:proj     ,
   		\	})

	let aucmds = [ 
			\	'StatusLine projs'                        ,
			\	'call projs#maps()'                       ,
			\	'call projs#proj#name("' . b:proj .'")'   ,
			\	'call projs#proj#secname("' . b:sec .'")' ,
			\	'call make#makeprg("projs_pdflatex",{"echo":0})'   ,
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

