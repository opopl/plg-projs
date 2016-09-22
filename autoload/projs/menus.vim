 
"""__SEE_ALSO

"""__USED_BY F_MenuAdd

"
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
	 	exe 'aunmenu &SECTIONS'
	 	exe 'aunmenu &FIGS'
	 	exe 'aunmenu &BASESECS'
	 	exe 'aunmenu &MAKEFILES'
	 	exe 'aunmenu &PFILES'
	 	exe 'aunmenu &OMNI'
 catch

 endtry

"""_ToolBar

			"\	'ToolBar.TEXHT' ,
			"\	'ToolBar.HTML' ,
			"\	'ToolBar.CFG' ,
	
	let menus_add=[
			\	'ToolBar.MAKE' ,
			\	'ToolBar.sep1' ,
			\	'ToolBar.VIEWPDF' ,
			\	'ToolBar.VIEWLOG' ,
			\	'ToolBar.sep2' ,
			\	'ToolBar.MAIN' ,
		 	\	'ToolBar.BODY' ,
			\	'ToolBar.PREAMBLE' ,
			\	'ToolBar.PACKAGES' ,
			\	'ToolBar.DEFS' ,
			\	'ToolBar.sep3' ,
			\	'ToolBar.HTLATEX' ,
			\	'ToolBar.sep4' ,
			\	'TOOLS.VIEWPDF' ,
			\	'TOOLS.VIEWLOG' ,
			\	'TOOLS.VIEW.idx' ,
			\	'TOOLS.VIEW.ind' ,
			\	'TOOLS.VIEW.aux' ,
			\	'TOOLS.VIEW.lof' ,
			\	'TOOLS.VIEW.lot' ,
			\	'TOOLS.RWPACK' ,
			\	'OMNI.proj_defs' ,
			\	'OMNI.proj_secs' ,
			\	'OMNI.projs' ,
			\	'OMNI._smart_tex' ,
			\	'OMNI.snippets' ,
			\	'OMNI.tex_plaintex_commands' ,
			\	'OMNI.tex_TEXHT_commands' ,
			\	]

	call base#menus#add(menus_add)

"""PROJS
 let lev=10
 for proj in sort(projs)
   let lett=toupper(matchstr(proj,'^\zs\w\ze'))

	 call base#menu#additem({
					\	'item' 	: '&PROJS.&' . lett . '.&' . proj,
	 				\	'cmd'		:	'PrjView ' . proj,
	 				\	'lev'		:	lev,
	 				\	})

	 let lev+=10
 endfor

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
 for sec in projs#varget('secnames',[])
   	if sec =~ '^fig\.'
	  		let fig=matchstr(sec,'^fig\.\zs.*\ze$')

		 		call base#menu#additem({
						\	'item' 	: '&FIGS.&' . fig,
		 				\	'cmd'		:	'VSEC ' . sec,
		 				\	'lev'		:	levs.FIGS . '.' . lev,
		 				\	})

		else

			let sec=substitute(sec,'\.','\\.','g')

		 		call base#menu#additem({
						\	'item' 	: '&SECTIONS.&' . sec,
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
						\	'item' 	: '&BASESECS.&' . sec,
		 				\	'cmd'		:	'VSECBASE ' . sec,
		 				\	'lev'		:	levs.BASESECS . '.' . lev,
		 				\	})
		let lev+=10
 endfor
 
endfunction
