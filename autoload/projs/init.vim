
" Used: 
"   in projs#init()
"
" Usage:
" 	call projs#init#root ()
" 	call projs#init#root (rootid)
" Purpose:
" 	set the value of 'root' from:
" 		-	 rootid, if given as first argument
" 		-	 PROJSDIR env variable, if called with no arguments
" Returns:
"		return [root,rootid]

function! projs#init#root (...)

		let rootid = projs#varget('rootid','')
		let rootid = get(a:000,0,'')

		let root   = projs#varget('root',base#envvar('PROJSDIR'))

		if !len(root)
    	let rootid = projs#varget('rootid','texdocs')
    	call projs#varset('rootid',rootid)
		endif

		if len(rootid)
			let dir     = base#path(rootid)

			if !strlen(dir)
				let dir = rootid
			endif

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

function! projs#init#templates (...)
	let tdir=base#qw#catpath('plg','projs templates')

	if !isdirectory(tdir)
		return
	endif

	let t={}
	let template_types=projs#varget('template_types',[])

	for k in template_types 
		let t[k] = projs#varget('templates_'.k,{})
		let te   = t[k]

		let d    = base#file#catfile([ tdir, k ])

		if !isdirectory(tdir) | continue | endif

		let ext  = k
		let exts = base#qw(ext)

		let found = base#find({ 
				\	"dirs"    : [d],
				\	"exts"    : exts,
				\	"cwd"     : 0,
				\	"relpath" : 1,
				\	"rmext"   : 1,
				\	})
		for f in found
			let p = base#file#catfile([ d, f .'.'.ext ])
			if !filereadable(p)
				call projs#warn('File NOT exist:'."\n\t".p)
			endif
			let lines=readfile(p)
			let te[f]=lines
		endfor

		call projs#varset('templates_'.k,te)
	endfor
	call projs#update('varlist')

endfunction

function! projs#init#au (...)
	let root   = projs#root()
	let root_u = base#file#win2unix(root)

	augroup plg_projs
		au!
		autocmd BufWinEnter,BufRead,BufNewFile *.cld setf tex
		exe 'autocmd BufWinEnter,BufRead,BufNewFile '. root_u  .'/**/*.csv  call projs#au#file_onload_csv() '
	augroup end
endfunction
