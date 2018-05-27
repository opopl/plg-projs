

"projs#sec#rename( new,old ) 

function! projs#sec#rename (...)
	let new = get(a:000,0,'')

	let old = projs#proj#secname()
	let old = get(a:000,1,old)

	if !strlen(new)
		let new = input('[sec='.old.' ] New section name: ','','custom,projs#complete#secnames')
	endif

	let oldf = projs#secfile(old)
	let newf = projs#secfile(new)

	call rename(oldf,newf)

	let lines = readfile(newf)

	let nlines = []
	let pat = '^\(%%file\s\+\)\(\w\+\)\s*$'
	for line in lines
		if line =~ pat
			let line = substitute(line,pat,'\1'.new,'g')
		endif

		call add(nlines,line)
	endfor

	call writefile(nlines,newf)

 	let pfiles = projs#proj#files()
perl << eof
	use List::MoreUtils::XS qw(bremove);
	
	my $pfiles = VimVar('pfiles');
	my $oldf   = VimVar('oldf');

	@$pfiles = bremove { $oldf cmp $_ }, @$pfiles ;

	VimLet('pfiles',$pfiles);
	VimMsg(Dumper($pfiles));
eof
	echo pfiles

	call projs#proj#secnames()
	
endfunction

function! projs#sec#delete (...)

	let sec = projs#proj#secname()
	let sec = get(a:000,0,sec)

	let secfile   = projs#secfile(sec)
	let secfile_u = base#file#win2unix(secfile)

	if filereadable(secfile)
		let cmd = 'git rm ' . secfile_u . ' --cached '
		let ok = base#sys({ 
			\	"cmds"         : [cmd],
			\	"split_output" : 0,
			\	"skip_errors"  : 1,
			\	})
	else
		call projs#warn('Section file does not exist for: '.sec)
		return
	endif

	let ok = base#file#delete({ 'file' : secfile })

	if ok
		call projs#echo('Section has been deleted: '.sec)
	endif

endfunction

function! projs#sec#onload (sec)
	let sec=a:sec

	let prf={ 'prf' : 'projs#sec#onload' }
	call base#log([
		\	'sec => ' . sec,
		\	],prf)
	call projs#sec#add(sec)

	return
endfunction

function! projs#sec#add (sec)
	let sec   = a:sec

	let sfile = projs#secfile(sec)
	let sfile = fnamemodify(sfile,':p:t')

	let pfiles =	projs#proj#files()
	if !base#inlist(sfile,pfiles)
			call add(pfiles,sfile)

			let f_listfiles=projs#secfile('_dat_files_')
			call base#file#write_lines({ 
				\	'lines' : pfiles, 
				\	'file'  : f_listfiles, 
				\})
	endif

	if !projs#sec#exists(sec)
		let secnames    = base#varget('projs_secnames',[])
		let secnamesall = base#varget('projs_secnamesall',[])

		call add(secnames,sec)
		call add(secnamesall,sec)

		let secnamesall = base#uniq(secnamesall)
		let secnames    = base#uniq(secnames)
	endif
	
endfunction

function! projs#sec#exists (...)
	let sec = get(a:000,0,'')

	let secnamesall = projs#proj#secnamesall ()

	return base#inlist(sec,secnamesall)

endfunction
