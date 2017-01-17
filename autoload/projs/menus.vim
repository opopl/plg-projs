 
"""__SEE_ALSO

"""__USED_BY F_MenuAdd

"
"
function! projs#menus#remove(...)

 try
	 	exe 'aunmenu &BASESECS'
	 	exe 'aunmenu &BUFFERS'
	 	exe 'aunmenu &MAKEFILES'
	 	exe 'aunmenu &MENUS'
	 	exe 'aunmenu &PROJS.&SECTIONS'
	 	exe 'aunmenu &PROJS.&BASESECS'
	 	exe 'aunmenu &PROJS'
	 	exe 'aunmenu &SECTIONS'
	 	exe 'aunmenu &TEX'
	 	exe 'aunmenu &TOOLS'
 catch

 endtry
endf

function! projs#menus#set(...)

 let projs = projs#list()

 if exists("&tbis")
 		set tbis=large
 endif

 let levs={
			 \	'FIGS' 			: 10,
			 \	'TEX' 			: 11,
			 \	'SECTIONS' 	: 12,
			 \	'BASESECS' 	: 13,
			 \	'PROJS' 		: 14,
			 \	'MAKEFILES' : 15,
			 \	'PFILES' 		: 16,
			 \	}

 try
	 	exe 'aunmenu &PROJS.&SECTIONS'
	 	exe 'aunmenu &FIGS'
	 	exe 'aunmenu &BASESECS'
	 	exe 'aunmenu &MAKEFILES'
	 	exe 'aunmenu &PFILES'
	 	exe 'aunmenu &OMNI'
 catch

 endtry

"""_ToolBar

	let menus_add=projs#varget('menus_add',[])
	call base#menus#add(menus_add)

"""PROJS
 let lev=10
 call projs#echo('Adding Menu: PROJS')

 let pdirs=projs#varget('projsdirs',[])

 for proj in sort(projs)
   let lett=toupper(matchstr(proj,'^\zs\w\ze'))

	 call base#menu#additem({
					\	'item' 	: '&PROJS.&LIST.&' . lett . '.&' . proj,
	 				\	'cmd'		:	'PrjView ' . proj,
	 				\	'lev'		:	lev,
	 				\	})

	 let lev+=10
 endfor

 for pdir in sort(pdirs)
	 call base#menu#additem({
					\	'item' 	: '&PROJS.&DIRS.&' . pdir,
	 				\	'cmd'		:	'ProjsInit ' . pdir,
	 				\	'lev'		:	lev,
	 				\	})
 endfor

"""COMMANDS
	let cmds = [
			\	'PrjAct',	
			\	'PrjMake',	
			\	'PrjSwitch',	
			\	'PrjUpdate',	
			\	]

"""PFILES
 let pfiles=[]
 let filesdat=base#catpath('projs',proj . '.files.i.dat' )

 if filereadable(filesdat)
	 let pfiles = base#readdatfile({	'file' : filesdat })
	
	 for fname in pfiles
		 	 let pfile=base#catpath('projs',proj . '.' . fname)
	
			 let fname=substitute(fname,'\.','\\.','g')
				
			 call base#menu#additem({
						\	'item' 	: '&PFILES.&' . fname,
		 				\	'cmd'		:	'call base#fileopen("' . pfile . '")',
		 				\	'lev'		:	lev,
		 				\	})
	 endfor
 endif


"""EFILES
 let efiles   = []
 let filesdat = base#catpath('projs',proj . '.files_ext.i.dat' )

 if filereadable(filesdat)
	 let efiles=base#readdatfile({	'file' : filesdat })
	
	 for fname in efiles
		 	 let pfile=base#catpath('projs',fname)
	
			 let fname=substitute(fname,'\.','\\.','g')
				
			 call base#menu#additem({
						\	'item' 	: '&EFILES.&' . fname,
		 				\	'cmd'		:	'call base#fileopen("' . pfile . '")',
		 				\	'lev'		:	lev,
		 				\	})
	
	 endfor
 endif

"""MAKEFILES
 "MenuAdd makefiles

"""SECTIONS
 let lev=10
 let secnames=projs#proj#secnames()

 for sec in secnames
   	if sec =~ '^fig\.'
	  		let fig=matchstr(sec,'^fig\.\zs.*\ze$')

		 		call base#menu#additem({
						\	'item' 	: '&PROJS.&FIGS.&' . fig,
		 				\	'cmd'		:	'VSEC ' . sec,
		 				\	'lev'		:	levs.FIGS . '.' . lev,
		 				\	})

		else
				let sec=substitute(sec,'\.','\\.','g')

		 		call base#menu#additem({
						\	'item' 	: '&PROJS.&SECTIONS.&' . sec,
		 				\	'lev'		:	levs.SECTIONS . '.' . lev,
		 				\	'cmd'		:	'VSEC ' . sec,
		 				\	} )

		endif
		let lev+=10
 endfor

"""BASESECS
 let lev=10
 for sec in projs#varget('secnamesbase',[])
 		call base#menu#additem({
						\	'item' 	: '&PROJS.&BASESECS.&' . sec,
		 				\	'cmd'		:	'VSECBASE ' . sec,
		 				\	'lev'		:	levs.BASESECS . '.' . lev,
		 				\	})
		let lev+=10
 endfor
 
endfunction
