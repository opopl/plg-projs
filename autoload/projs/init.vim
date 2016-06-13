
function! projs#init#root (...)

		let rootid = get(a:000,0,'')

		let root   = projs#varget('root',base#envvar('PROJSDIR'))

		if !len(root)
    	let rootid = projs#varget('rootid','texdocs')
		endif

		if len(rootid)
			let dir     = base#path(rootid)
      call base#mkdir(dir)
			let root = dir
    endif

  	if isdirectory(root)
    		call projs#varset('rootid',rootid)
     		call projs#varset('root',root)
    endif


    call base#pathset({ 'projs' : root })

		return [root,rootid]
	
endfunction
