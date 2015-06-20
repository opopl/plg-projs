
function! projs#viewproj (...)

 CD projs

 """ delete buffers from the previously loaded project
 "RFUN DC_Proj_BufsDelete
 "BuffersWipeAll

 let sec=''
 if a:0
    let g:proj=matchstr(a:1,'^\zs\w\+\ze')
    let sec=matchstr(a:1,'^\w\+\.\zs\w\+\ze')

 endif

 let pm='TeX::Project::Generate::' . g:proj
 let loadpm=input('Load project module ' . pm . '(y/n)? :','n' )
 if loadpm == 'y'
	exe 'tag ' . pm
 endif

 let g:DC_Proj_SecOrderFile=F_CatPath('projs', g:proj . '.secorder.i.dat' )

 let var='g:DC_Proj_SecName'
 if ! strlen(sec)
  	let {var}='_main_'
 else
  	let {var}=sec
 endif

 call DC_Proj_CheckSecDir()
 call F_VarUpdate('DC_Proj_SecNames')
 
 call DC_Proj_OpenSec(g:DC_Proj_SecName)

 let menuprojs=input('Load projs menu? (y/n): ', 'n')
 if menuprojs == 'y'
	 		MenuReset projs
 endif

 RFUN SubNameEnd
endfun

	
endfunction
