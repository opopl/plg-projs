

function! projs#buf#vim ()
	TgSet projs_this
endfunction

function! projs#buf#tex_tex ()

	call projs#onload()

	let b:proj = substitute(b:basename,'^\(\w\+\)\..*','\1','g')

	if base#inlist(b:proj,base#qw('inc jnames defs'))
		return
	endif

	if (b:proj =~ '^'.'_def')
		return
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
			\	'call projs#proj#name("' . b:proj .'")'   ,
			\	'call projs#proj#secname("' . b:sec .'")' ,
			\	'call make#makeprg("'.mprg.'",{"echo":0})',
			\	'call projs#onload()'                     ,
			\	] 

	let fr = '  autocmd BufWinEnter,BufRead,BufEnter,BufWritePost,BufNewFile '
	
	let b:ufile = base#file#win2unix(b:file)
	
	exe 'augroup projs_p_' . b:proj . '_' . b:sec
	exe '  au!'
	for cmd in aucmds
		exe join([ fr,b:ufile,cmd ],' ')
	endfor
	exe 'augroup end'
	
endfunction

function! projs#buf#tex_sty ()

endfunction
