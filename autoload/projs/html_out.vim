
function! projs#html_out#file (...)
	let ref = get(a:000,0,{})

	let proj = projs#proj#name()
	let proj = get(ref,'proj',proj)

	let hroot = projs#html_out#root()
	
	let hfile = join([ hroot, proj, 'main.html' ], '/')
	let hfile = base#file#win2unix(hfile)

	return hfile
	
endfunction

function! projs#html_out#view (...)
	let hfile = projs#html_out#file()

	let browser = base#envvar('browser','')

	let cmd = join([browser,shellescape(hfile)],' ' )
	
	let env = {}
	function env.get(temp_file) dict
		let code = self.return_code

		call base#rdw('OK: browser open')
	endfunction
	
	call asc#run({ 
		\	'cmd' : cmd, 
		\	'Fn'  : asc#tab_restore(env) 
		\	})

endfunction

function! projs#html_out#root (...)
	let hroot = base#envvar('htmlout','')
	return hroot
endfunction
