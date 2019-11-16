
"---------------------------------
"
"	Section-related functions:
"
"		projs#sec#new(sec)
"
"		projs#sec#rename(new, old)
"
"		projs#sec#open(sec)
"		projs#sec#append({ sec : sec, lines : lines })
"
"---------------------------------
"
function! projs#sec#append (...)
	let ref = get(a:000,0,{})

	let sec   = get(ref,'sec','')
	let lines = get(ref,'lines',[])

	let file = projs#sec#file(sec)

	let r = {
			\	'lines' : lines,
			\	'file' : file,
			\	'mode' : 'append',
			\	}
	call base#file#write_lines(r)

endf

"projs#sec#rename( new,old ) 

function! projs#sec#rename (...)
	let new = get(a:000,0,'')

	let old = projs#proj#secname()
	let old = get(a:000,1,old)

	if !strlen(new)
		let new = input('[sec='.old.' ] New section name: ','','custom,projs#complete#secnames')
	endif

	let oldf = projs#sec#file(old)
	let newf = projs#sec#file(new)

	let oldf_base = projs#sec#file_base(old)
	let newf_base = projs#sec#file_base(new)

	call rename(oldf,newf)

	let lines = readfile(newf)

	let nlines = []
	let pats = {}
	call extend(pats,{ '^\(%%file\s\+\)\(\w\+\)\s*$' : '\1'.new  })
	call extend(pats,{ '^\(\\label{sec:\)'.old.'\(}\s*\)$' : '\1'.new.'\2' })
	
	for line in lines
		for [pat,subpat] in items(pats)
			if line =~ pat
				let line = substitute(line,pat,subpat,'g')
			endif
		endfor

		call add(nlines,line)
	endfor

	call writefile(nlines,newf)

 	let pfiles = projs#proj#files()
  let ex = {}
  for pfile in pfiles
    call extend(ex,{ pfile : 1 })
  endfor
  call extend(ex,{ newf_base : 1, oldf_base : 0 })

	let pfiles=[]
	for [file,infile] in items(ex)
		if infile
			call add(pfiles,file)
		endif
	endfor

  let f_listfiles = projs#sec#file('_dat_files_') 

	call base#file#write_lines({ 
			\	'lines' : pfiles,
			\	'file'  : f_listfiles,
			\})

	call projs#proj#secnames()
	call base#fileopen({ 'files' : [newf]})
	
endfunction

function! projs#sec#delete (...)

	let sec = projs#proj#secname()
	let sec = get(a:000,0,sec)

	let secfile   = projs#sec#file(sec)
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
		call projs#echo('Section has been deleted: ' . sec)
	endif

endfunction

function! projs#sec#onload (sec)
	let sec = a:sec

	let prf = { 'prf' : 'projs#sec#onload' }
	call base#log([
		\	'sec => ' . sec,
		\	],prf)
	call projs#sec#add(sec)

	return
endfunction

function! projs#sec#parent ()
	let parent = projs#varget('parent_sec','')
	return parent
endfunction

function! projs#sec#file (...)
  let proj = projs#proj#name()

  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  let secfile = projs#path( projs#sec#file_base_a(sec) )
  return secfile
endf

function! projs#sec#filecheck (...)
    let sec = a:1
    let sfile = projs#sec#file(sec)

    if !filereadable(sfile)
        call projs#sec#new(sec)
    endif

    return 1
endf


function! projs#sec#file_base (...)
  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  let sfile_a = projs#sec#file_base_a(sec)

  let sfile = base#file#catfile(sfile_a)
  return sfile
endf

function! projs#sec#file_base_a (...)
    
    let sec = projs#proj#secname()
    let sec = get(a:000,0,sec)

    let dot = '.'

    let proj = projs#proj#name()
    let sfile_a = []

    let runext = (has('win32')) ? 'bat' : 'sh' 

    if sec == '_main_'
        let sfile_a = [ proj.'.tex']

    elseif sec == '_vim_'
        let sfile_a = [ proj.'.vim']

    elseif sec == '_pl_'
        let sfile_a = [ proj.'.pl']

    elseif sec == '_osecs_'
        let sfile_a = [ proj.'.secorder.i.dat']

    elseif sec == '_dat_'
        let sfile_a = [ proj . '.secs.i.dat' ]

    elseif sec == '_dat_defs_'
      let sfile_a = [ proj . '.defs.i.dat' ]

    elseif sec == '_dat_files_'
      let sfile_a = [ proj . '.files.i.dat' ]

    elseif sec == '_dat_files_ext_'
      let sfile_a = [ proj . '.files_ext.i.dat' ]

    elseif sec == '_dat_citn_'
        let sfile_a = [ proj.'.citn.i.dat']

    elseif sec == '_bib_'
        let sfile_a = [ proj.'.refs.bib']

    elseif sec == '_xml_'
        let sfile_a = [ proj.'.xml' ]

    elseif sec == '_join_'
        let sfile_a = [ 'joins', proj . '.tex' ]

    elseif sec == '_build_pdflatex_'
        let sfile_a = [ 'b_' . proj . '_pdflatex.'.runext ]

    elseif sec == '_build_perltex_'
        let sfile_a = [ 'b_' . proj . '_perltex.'.runext ]

    elseif sec == '_build_htlatex_'
        let sfile_a = [ 'b_' . proj . '_htlatex.'.runext ]

    elseif sec == '_main_htlatex_'
        let sfile_a = [ proj . '.main_htlatex.tex' ]

    else
        let sfile_a = [proj.dot.sec.'.tex']

    endif

    return sfile_a
    
endfunction


"	projs#sec#add
"
"	Purpose:
"		
"	Usage:
"		call projs#sec#add (sec)
"	Returns:
"		
"
"	Call tree:
"		calls:
"			projs#proj#name
"			projs#sec#file
"			projs#proj#files
"			base#file#write_lines
"			projs#sec#exists
"			projs#db#file
"		called by:
"			

function! projs#sec#add (sec)
	let sec   = a:sec

	let proj = projs#proj#name()

	let sfile = projs#sec#file(sec)
	let sfile = fnamemodify(sfile,':p:t')

	let pfiles =	projs#proj#files()
	if !base#inlist(sfile,pfiles)
		call add(pfiles,sfile)
	
		let f_listfiles = projs#sec#file('_dat_files_')
		call base#file#write_lines({ 
			\	'lines' : pfiles, 
			\	'file'  : f_listfiles, 
			\})
	endif

	if ! projs#sec#exists(sec)
		let secnames    = base#varget('projs_secnames',[])
		let secnamesall = base#varget('projs_secnamesall',[])

		call add(secnames,sec)
		call add(secnamesall,sec)

		let secnamesall = base#uniq(secnamesall)
		let secnames    = base#uniq(secnames)
	endif

	let dbfile  = projs#db#file()
	
	let t = "projs"
	let h = {
		\	"proj"   : proj,
		\	"sec"    : sec,
		\	"file"   : sfile,
		\	"root"   : projs#root(),
		\	"rootid" : projs#rootid(),
		\	"tags"   : "",
		\	"author" : "",
		\	}
	
	let ref = {
		\ "dbfile" : dbfile,
		\ "i"      : "INSERT OR IGNORE",
		\ "t"      : t,
		\ "h"      : h,
		\ }
		
	call pymy#sqlite#insert_hash(ref)

endfunction

function! projs#sec#exists (...)
	let sec = get(a:000,0,'')

	let secnamesall = projs#proj#secnamesall ()

	return base#inlist(sec,secnamesall)

endfunction

" projs#sec#new(sec)
" projs#sec#new(sec,{ "git_add" : 1 })
" projs#sec#new(sec,{ "view" : 1 })
" projs#sec#new(sec,{ "prompt" : 0 })
" projs#sec#new(sec,{ "rewrite" : 1 })

function! projs#sec#new(sec,...)
    let sec        = a:sec

    let proj       = projs#proj#name()
		let parent_sec = projs#sec#parent()

    let ref = { 
        \   "git_add" : 0, 
        \   "view"    : 0, 
        \   "prompt"  : 1, 
        \   "seccmd"  : '', 
        \   "lines"   : [], 
        \   }

    call extend(ref,{ "prompt" : 0 })

    if a:0 
        let refadd = get(a:000,0,{})
        call extend(ref, refadd)
    endif

		let rw = get(ref,'rewrite',0)
		if projs#sec#exists(sec)
			if !rw
				return
			endif
		endif

    let o = base#varget('projs_opts_PrjSecNew',{})

    let prompt = get(o,'prompt',1)
    let prompt = get(ref,'prompt',prompt)

    call projs#echo("Creating file:\n\t" . sec )

    let lines = []
    call extend(lines,get(ref,'add_lines_before',[]))

    let file = projs#sec#file(sec)

    let secs = base#qw("preamble body")

    let projtype = projs#varget('projtype','regular')

    let sub = 'projs#newseclines#'.projtype.'#'.sec

    let lines = []

    let tagsec = [' ' , '%%file '.sec, ' ' ]
		call extend(tagsec,[' ','%%parent ' . parent_sec ,' '])

    let keymap = 'ukrainian-jcuken'
    let keymap = 'russian-jcukenwin'
    "let keymap = input('Keymap:','','custom,txtmy#complete#keymap')

    try
      exe 'let lines='.sub.'()'
    catch 
      call projs#warn('Problems while executing:'."\n\t".sub)
    endtry

    let inref = { 'prompt' : prompt }

"""newsec__main__
    if sec == '_main_'

      let file = projs#path([ proj.'.tex'])

    elseif sec =~ '^fig_'
				let num = substitute(sec,'^fig_\(.*\)$','\1','g')
				let num_dot = substitute(num,'_','.','g')

        call extend(lines,tagsec)

				call add(lines,'\renewcommand{\thefigure}{'.num_dot.'}')
				call add(lines,'	')
				call add(lines,'\begin{figure}[ht]')
				call add(lines,'	\begin{center}')
				call add(lines,'		\PrjPicW{'.num.'}{0.7}')
				call add(lines,'	\end{center}')
				call add(lines,'	')
				call add(lines,'	\caption{')
				call add(lines,'	')
				call add(lines,'	}')
				call add(lines,'	\label{fig:'.num.'}')
				call add(lines,'\end{figure}')
				call add(lines,'	')

"""newsec_listfigs
    elseif sec == 'listfigs'

        call extend(lines,tagsec)

				call add(lines,' ')
				call add(lines,'\phantomsection')
				call add(lines,' ')
				call add(lines,'\addcontentsline{toc}{chapter}{\listfigurename} ')
				call add(lines,' ')
				call add(lines,'\listoffigures')
				call add(lines,'\newpage')
				call add(lines,' ')

"""newsec_listtabs
    elseif sec == 'listtabs'

        call extend(lines,tagsec)

				call add(lines,' ')
				call add(lines,'\phantomsection')
				call add(lines,' ')
				call add(lines,'\addcontentsline{toc}{chapter}{\listtablename} ')
				call add(lines,' ')
				call add(lines,'\listoftables')
				call add(lines,'\newpage')
				call add(lines,' ')
 
"""newsec_bib
    elseif sec == 'bib'

        let bibstyle = base#input('Bibliography style:','unsrt',inref)
        let bibfile  = base#input('Bibliography:','\PROJ.refs',inref)

        call extend(lines,tagsec)

        call add(lines,'\phantomsection')
        "call add(lines,'\renewcommand\bibname{}')

        call add(lines,'\addcontentsline{toc}{chapter}{\bibname}')

        call add(lines,'\bibliographystyle{'.bibstyle.'}')
        call add(lines,'\bibliography{'.bibfile.'}')
"""newsec_title
    elseif sec == 'title'
        call add(lines,' ')
        call add(lines,'\begin{titlepage}')
        call add(lines,' ')
        call add(lines,'\end{titlepage}')

"""newsec_index
    elseif sec == 'index'

        call extend(lines,tagsec)

        call add(lines,'\clearpage')
        call add(lines,'\phantomsection')
        call add(lines,'\addcontentsline{toc}{chapter}{\indexname}')
        call add(lines,'\printindex')

"""newsec_body
    elseif sec == 'body'
        call extend(lines,tagsec)

"""newsec_cfg
    elseif sec == 'cfg'
        call extend(lines,tagsec)

        call extend(lines,tex#lines('tex4ht_cfg'))

"""newsec_preamble
    elseif sec == 'preamble'
        call extend(lines,tagsec)

        let packs = projs#varget('tex_packs_preamble',[])

        let packopts = {
            \ 'fontenc'  : 'OT1,T2A,T3',
            \ 'inputenc' : 'utf8',
            \ }

        let ln  = projs#qw#rf('data tex preamble.tex')
        call extend(lines,ln)

    elseif sec == '_dat_'

    elseif sec == '_dat_defs_'

"""newsec__pl_
    elseif sec == '_pl_'

perl << eof
      use Vim::Perl qw(:funcs :vars);

      my $proj  = VimVar('proj');
      my $lines = [];

      push @$lines,map { s/^\s*//g; $_} split "\n" => qq{
        use strict;
        use warnings;
        use utf8;

        use Data::Dumper;
        use FindBin qw(\$Bin \$Script);

        my \$proj=\"$proj\";
      };

      VimListExtend('lines',$lines);
eof

"""newsec__vim_
    elseif sec == '_vim_'

        let q_proj     = txtmy#text#quotes(proj)
        let q_projtype = txtmy#text#quotes(projtype)

        call add(lines,' ')
        call add(lines,'"""_vim_ ')
        call add(lines,' ')
        call add(lines,'let s:projtype ='.q_projtype)
        call add(lines,'let s:proj     ='.q_proj)
        call add(lines,' ')
        call add(lines,'call projs#proj#name(s:proj)')
        call add(lines,'call projs#proj#type(s:projtype)')
        call add(lines,' ')
        call add(lines,'PrjVarSet exe_latex pdflatex ')
        call add(lines,' ')

    elseif sec == '_bib_'

"""newsec__build_htlatex
    elseif sec == '_build_htlatex_'

        let secc = base#qw('_main_htlatex_ cfg')
        for sec in secc
            call projs#sec#filecheck(sec)
        endfor

        let outd = [ 'builds', proj, 'b_htlatex' ]

        let pcwin = [ '%Bin%' ]
        let pcunix = [ '.' ]

        call extend(pcwin,outd)
        call extend(pcunix,outd)

        let outdir_win = base#file#catfile(pcwin)

        let outdir_unix = base#file#catfile(pcunix)
        let outdir_unix = base#file#win2unix(outdir_unix)

        let tex_opts  = ' -file-line-error '
        let tex_opts .= ' -output-directory='. outdir_unix

        call add(lines,' ')
        call add(lines,'set Bin=%~dp0')
        call add(lines,' ')
        call add(lines,'set htmout='.base#path('htmlout') )
        call add(lines,'set htmloutdir=%htmlout%\'.proj)
        call add(lines,'set htmloutdir_pics=%htmloutdir%\pics\'.proj)
        call add(lines,' ')

        call add(lines,'if exist %htmloutdir% rmdir /q/s  %htmloutdir% ')
        call add(lines,' ')
        call add(lines,'md %htmloutdir%')
        call add(lines,'md %htmloutdir_pics%')
        call add(lines,' ')
        call add(lines,'set outdir='.outdir_win)
        call add(lines,'set outdir_pics=%outdir%\pics\'.proj)
        call add(lines,' ')

        call add(lines,'if  exist %outdir% rmdir /q/s  %outdir% ')
        call add(lines,' ')
        call add(lines,'md %outdir%')
        call add(lines,'md %outdir_pics%')
        call add(lines,' ')
        call add(lines,'cd %Bin%')
        call add(lines,' ')
        call add(lines,'copy '.proj.'.*.tex %outdir%' )
        call add(lines,'copy '.proj.'.tex %outdir%' )
        call add(lines,'copy *.sty %outdir%' )
        call add(lines,'copy _def.*.tex %outdir%' )
        call add(lines,'copy inc.*.tex %outdir%' )
        call add(lines,' ')
        call add(lines,'copy pics\'.proj.'\*.jpg %outdir_pics%\' )
        call add(lines,'copy pics\'.proj.'\*.png %outdir_pics%\' )
        call add(lines,' ')
        call add(lines,'cd %outdir%')
        call add(lines,' ')
        call add(lines,'copy '.proj.'.cfg.tex main.cfg' )
        call add(lines,'copy '.proj.'.main_htlatex.tex main.tex' )
        call add(lines,' ')
        call add(lines,'htlatex main main')
        call add(lines,' ')
        call add(lines,'copy *.html %htmloutdir%\ ')
        call add(lines,'copy *.png %htmloutdir%\ ')
        call add(lines,' ')
        call add(lines,'copy %outdir_pics%\*.png %htmloutdir_pics%')
        call add(lines,'copy %outdir_pics%\*.jpg %htmloutdir_pics%')
        call add(lines,' ')
        call add(lines,'cd %Bin% ')
        call add(lines,' ')

        call projs#sec#new('_main_htlatex_')

    elseif sec == '_main_htlatex_'

        call add(lines,' ')
        call add(lines,'%%file '. sec)
        call add(lines,' ')
        call add(lines,'\nonstopmode')
        call add(lines,' ')

        let mf = projs#sec#file('_main_')
        let ml = readfile(mf)

        call filter(ml,'v:val !~ "^%%file f_main"')

        call extend(lines,ml)

    elseif sec == '_dat_files_'
        let files = projs#proj#files()
        call extend(lines,files)


"""newsec__build_perltex_
"""newsec__build_pdflatex
    elseif base#inlist(sec,base#qw('_build_perltex_ _build_pdflatex_'))
        let type = substitute(sec,'^_build_\(\w\+\)_$','\1','g')
        let tex_exe = type

        let outd = [ 'builds', proj, 'b_'.type ]

        let pcwin = [ '%Bin%' ]
        let pcunix = [ '.' ]

        call extend(pcwin,outd)
        call extend(pcunix,outd)

        let outdir_win = base#file#catfile(pcwin)

        let outdir_unix = base#file#catfile(pcunix)
        let outdir_unix = base#file#win2unix(outdir_unix)

        let tex_opts = []
        if type == 'perltex'
					call add(tex_opts,'--latex=pdflatex --nosafe')
        endif

				call add(tex_opts,' -file-line-error ')
				call add(tex_opts,' -interaction nonstopmode ')
				call add(tex_opts,' -output-directory='. outdir_unix)

        let lns = {
            \ 'texcmd'    : '%tex_exe% %tex_opts% ' . proj ,
            \ 'bibtex'    : 'bibtex '    . proj            ,
            \ 'makeindex' : 'makeindex ' . proj            ,
            \ }
        let bibfile = projs#sec#file('_bib_')

				call add(lines,' ')
				call add(lines,'@echo off ')
				call add(lines,' ')
				call add(lines,'set Bin=%~dp0')
				call add(lines,'cd %Bin%')
				call add(lines,' ')
				call add(lines,'set tex_exe='.tex_exe)
				call add(lines,' ')
				call add(lines,'set tex_opts=')
				for opt in tex_opts
					call add(lines,'set tex_opts=%tex_opts% ' . opt)
				endfor
				call add(lines,' ')
				call add(lines,'set outdir='.outdir_win)
				call add(lines,'md %outdir%')
				call add(lines,' ')
				call add(lines,'set bibfile='.bibfile)
				call add(lines,' ')
				call add(lines,'copy %bibfile% %outdir%')
				call add(lines,' ')
				call add(lines,lns.texcmd  )
				call add(lines,'rem --- bibtex makeindex --- ')
				call add(lines,'cd %outdir% ')
				call add(lines,lns.bibtex  )
				call add(lines,lns.makeindex  )
				call add(lines,'rem ------------------------ ')
				call add(lines,' ')
				call add(lines,'cd %Bin% ')
				call add(lines,lns.texcmd  )
				call add(lines,lns.texcmd  )
				call add(lines,' ')

        let origin = base#file#catfile([ outdir_win, proj.'.pdf'])

        let dests = []

        call add(dests,'%Bin%\pdf_built\b_'.proj.'.pdf' )
        call add(dests,'%PDFOUT%\b_'.type.'_'.proj.'.pdf' )
        call add(dests,'%PDFOUT%\'.proj.'.pdf' )

        for dest in dests
            call add(lines,'copy '.origin.' '.dest)
            call add(lines,' ')
        endfor
"""newsec_else
    else

        if strlen(keymap)
          call add(lines,'% vim: keymap='.keymap)
        endif

        call add(lines,' ')
        call add(lines,'%%file ' . sec)
        call add(lines,'%%parent ' . parent_sec )
        call add(lines,' ')

"""newsec_else_prompt
        if prompt 
          let cnt = input('Continue adding? (1/0):',1)
  
          if cnt
              let addsec = input('Add sectioning? (1/0):',1)
              if addsec
                  let seccmd = input('Sectioning command: ','section','custom,tex#complete#seccmds')
  
                  let title = input('Title: ',sec)
                  let label = input('Label: ','sec:'.sec)
  
                  call add(lines,'\' . seccmd . '{'.title.'}')
                  call add(lines,'\label{'.label.'}')
                  call add(lines,' ')
              endif
          endif
        else
"""newsec_else_no_prompt
            let seccmd= get(ref,'seccmd','section')

						if strlen(seccmd)
							let title = sec
							let label = 'sec:'.sec
	
							call add(lines,'\' . seccmd . '{'.title.'}')
							call add(lines,'\label{'.label.'}')
							call add(lines,' ')
						endif
        endif
 
    endif

    call extend(lines,get(ref,'add_lines_after',[]))

    call writefile(lines,file)

    if get(ref,'git_add')
        call base#sys("git add " . file)
    endif

    if get(ref,'view')
        exe 'split ' . file
    endif
    
		return 1
endfunction
"""end_projs_sec_new

function! projs#sec#open (...)
 let proj = projs#proj#name()

 let parent_sec = projs#proj#secname()

 if a:0 == 1
    let sec=a:1
 else
    let sec=projs#select#sec()
 endif

 if !projs#sec#exists(sec)
    let cnt = input('Section does not exist, continue? (1/0):',1)
    if !cnt | return | endif

    call projs#sec#add(sec)
 endif

  call projs#varset("secname",sec)

  let vfile             = ''
  let vfiles            = []

  if projs#varget('secdirexists',0)
    let vfile = projs#path([ proj, sec . '.tex' ])
  else
    let vfile = projs#sec#file(sec) 
  endif

  if sec == '_main_'
        for ext in projs#varget('extensions_tex',[])
            let vfile = projs#path([ proj . '.' . ext ])
                if filereadable(vfile)
                    call add(vfiles, vfile)
                endif
        endfor

  elseif sec == '_dat_'
    call projs#gensecdat()

    return
  elseif sec == '_osecs_'
    call projs#opensecorder()

    return

  elseif sec == '_join_'

    call projs#filejoinlines()

  elseif sec == '_pl_all_'
    call extend(vfiles,base#splitglob('projs',proj . '.*.pl'))
    call extend(vfiles,base#splitglob('projs',proj . '.pl'))
    let vfile=''

  else

    let vfile = projs#sec#file(sec)
  endif

  if strlen(vfile) 
    call add(vfiles,vfile)
  endif

  call projs#varset('curfile',vfile)

  let vfiles = base#uniq(vfiles)

	call projs#varset("parent_sec",parent_sec)

  for vfile in vfiles
    if !filereadable(vfile)
        call projs#sec#new(sec)
    endif
    call base#fileopen(vfile) 
  endfor


  call base#stl#set('projs')
  "KEYMAP russian-jcukenwin
  KEYMAP ukrainian-jcuken

  return 
endf
