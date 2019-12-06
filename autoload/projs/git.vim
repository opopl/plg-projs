
function! projs#git#save ()
	let root = projs#root()
	call base#cd(root)

	GitSave
	
endfunction
