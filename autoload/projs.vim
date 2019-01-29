
function! projs#secfilecheck (...)
    let sec = a:1
    let sfile = projs#secfile(sec)

    if !filereadable(sfile)
        call projs#newsecfile(sec)
    endif

    return 1
endf

function! projs#secfile (...)
  let proj = projs#proj#name()

  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  let secfile = projs#path(projs#secfile_base_a(sec))
  return secfile
endf

function! projs#secfile_base (...)
  let sec = projs#proj#secname()
  let sec = get(a:000,0,sec)

  let sfile_a = projs#secfile_base_a(sec)

  let sfile = base#file#catfile(sfile_a)
  return sfile
endf

" projs#secfile (sec)
"
function! projs#secfile_base_a (...)
    
    let sec = projs#proj#secname()
    let sec = get(a:000,0,sec)

    let dot = '.'

    let proj = projs#proj#name()
    let sfile_a = []

    let runext = (has('win32')) ? 'bat' : 'sh' 

    if sec == '_main_'
        let sfile_a = [proj.'.tex']

    elseif sec == '_vim_'
        let sfile_a = [proj.'.vim']

    elseif sec == '_pl_'
        let sfile_a = [proj.'.pl']

    elseif sec == '_osecs_'
        let sfile_a = [proj.'.secorder.i.dat']

    elseif sec == '_dat_'
        let sfile_a = [ proj . '.secs.i.dat' ]

    elseif sec == '_dat_defs_'
      let sfile_a = [ proj . '.defs.i.dat' ]

    elseif sec == '_dat_files_'
      let sfile_a = [ proj . '.files.i.dat' ]

    elseif sec == '_dat_files_ext_'
      let sfile_a = [ proj . '.files_ext.i.dat' ]

    elseif sec == '_dat_citn_'
        let sfile_a = [proj.'.citn.i.dat']

    elseif sec == '_bib_'
        let sfile_a = [proj.'.refs.bib']

    elseif sec == '_xml_'
        let sfile_a = [proj.'.xml']

    elseif sec == '_join_'
        let sfile_a = ['joins',proj.'.tex']

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

function! projs#namefromfile (...)
  let ref = {}
  if a:0 | let ref = a:1 | endif

  let file = get(ref,'file','')
  let bname = fnamemodify(file,':p:t')
  let name = substitute(bname,'^\(\w\+\)\..*$','\1','g')

  return name

endfunction

"call projs#secfromfile ({ "file" : file, "type" : "basename", "proj" : proj })

function! projs#secfromfile (...)
    let ref = {}
    if a:0 | let ref = a:1 | endif

    let proj = projs#proj#name()

    let file = get(ref,'file','')
    let type = get(ref,'type','basename')
    let proj = get(ref,'proj',proj)

    if type == 'basename'
        let basename = file 
    
        if basename =~ '^\w\+\.\(.*\)\.tex$'
            let sec = substitute(basename,'^\w\+\.\(.*\)\.tex$','\1','g')
        elseif basename == proj . '.tex' 
            let sec = '_main_'
        elseif basename =~ '\.\(\w\+\)\.vim$'
            let sec = '_vim_'
        elseif basename =~ '\.\(\w\+\)\.bib$'
            let sec = '_bib_'
        elseif basename =~ '\.\(\w\+\)\.bib$'
            let sec = '_unknown_'
        endif
        return sec
    endif

endfunction

" projs#newsecfile(sec)
" projs#newsecfile(sec,{ "git_add" : 1 })
" projs#newsecfile(sec,{ "view" : 1 })
" projs#newsecfile(sec,{ "prompt" : 0 })

function! projs#newsecfile(sec,...)

    let sec  = a:sec
    let proj = projs#proj#name()
		let parent_sec = projs#varget('parent_sec','')

    let ref = { 
        \   "git_add" : 0, 
        \   "view"    : 0, 
        \   "prompt"  : 1, 
        \   "seccmd"  : '', 
        \   "lines"   : [], 
        \   }

    call extend(ref,{ "prompt" : 0 })

    if a:0 
        let refadd = a:1 
        call extend(ref,refadd)
    endif

    let o = base#varget('projs_opts_PrjSecNew',{})

    let prompt = get(o,'prompt',1)
    let prompt = get(ref,'prompt',prompt)

    call projs#echo("Creating file:\n\t" . sec )

    let lines = []
    call extend(lines,get(ref,'add_lines_before',[]))

    let file = projs#secfile(sec)

    let secs = base#qw("preamble body")

    let projtype = projs#varget('projtype','regular')

    let sub = 'projs#newseclines#'.projtype.'#'.sec

    let lines = []

    let tagsec=[' ' , '%%file '.sec, ' ' ]
		call extend(tagsec,[' ','%%parent ' . parent_sec ,' '])

    let keymap = 'ukrainian-jcuken'
    let keymap = 'russian-jcukenwin'
    "let keymap = input('Keymap:','','custom,txtmy#complete#keymap')

    try
      exe 'let lines='.sub.'()'
    catch 
      call projs#warn('Problems while executing:'."\n\t".sub)
    endtry

    let inref={'prompt' : prompt }

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
        "call add(lines,'\renewcommand\bibname{<++>}')

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
            call projs#secfilecheck(sec)
        endfor

        let outd = [ 'builds', proj, 'b_htlatex' ]

        let pcwin = [ '%Bin%' ]
        let pcunix = [ '.' ]

        call extend(pcwin,outd)
        call extend(pcunix,outd)

        let outdir_win = base#file#catfile(pcwin)

        let outdir_unix = base#file#catfile(pcunix)
        let outdir_unix = base#file#win2unix(outdir_unix)

        let latexopts  = ' -file-line-error '
        let latexopts .= ' -output-directory='. outdir_unix

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

        call projs#newsecfile('_main_htlatex_')

    elseif sec == '_main_htlatex_'

        call add(lines,' ')
        call add(lines,'%%file '. sec)
        call add(lines,' ')
        call add(lines,'\nonstopmode')
        call add(lines,' ')

        let mf = projs#secfile('_main_')
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

        let latexopts = ''
        if type == 'perltex'
          let latexopts  .= ' --latex=pdflatex --nosafe'
        endif

        let latexopts .= ' -file-line-error '
        let latexopts .= ' -output-directory='. outdir_unix

        let lns = {
            \ 'texcmd'    : '%tex_exe% ' . latexopts .' '.proj ,
            \ 'bibtex'    : 'bibtex '    . proj            ,
            \ 'makeindex' : 'makeindex ' . proj            ,
            \ }
        let bibfile=projs#secfile('_bib_')

        call add(lines,' ')
        call add(lines,'set Bin=%~dp0')
        call add(lines,'set tex_exe='.tex_exe)
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
    
endfunction

function! projs#help (...)
    echo ' '
    echo 'PROJS PLUGIN HELP'
    echo ' '

    let topics=base#qw('maps')

    let topic = base#getfromchoosedialog({ 
            \ 'list'        : topics,
            \ 'startopt'    : get(topics,0,''),
            \ 'header'      : "Available help topics are: ",
            \ 'numcols'     : 1,
            \ 'bottom'      : "Choose a help topic by number: ",
            \ })

    if topic == 'maps'
        let yn=input('Show projs#maps() ? (1/0):',1)
        if yn | call base#vim#showfun('projs#maps') | endif
    endif

endfunction

"
"
"""projs_new

"" projs#new()
"" projs#new(proj)
"" projs#new(proj,{ git_add : 1 })
"

function! projs#new (...)
 call base#echoprefix('(projs#new)')

 let delim = repeat('-',50)
 let proj  = ''

 echo delim
 echo " "
 echo "This will create a new TeX project skeleton "
 echo "    in projects' root directory: " . projs#root() 
 echo " "
 echo delim

 let yn=input('Continue? (1/0): ',1)
 if !yn | return 0 | endif

 let newopts=projs#varget('PrjNew_opts',{})
  
 if a:0
     let proj     = a:1
     let projtype = 'regular'

     if (a:0 == 2 && ( base#type(a:2) == 'Dictionary'))
        call extend(newopts,a:2)
     endif
 else
     if !strlen(proj)
        let proj = input('New project name:','','custom,projs#complete')
     endif
 endif

 if ! strlen(proj)
     call base#warn({ 'text' : 'no project name provided' })
     return 0 
 endif

 let projtype   = projs#select#projtype()
 let projstruct = projs#select#projstruct()

 call projs#rootcd()
 
 if projs#ex(proj)
    let rw = input('Project already exists, rewrite (1/0)?: ',0)

    if !rw | return 0 | endif
 endif

  call projs#proj#name(proj)
  call projs#varset('projtype',projtype)

  let texfiles =  projs#update#texfiles()

  let nsecs_h = {
      \ "single_file"   : "_main_",
      \ "regular"       : "_main_ preamble body cfg bib index listfigs listtabs tabcont",
      \ }
  let nsecs_s = get(nsecs_h,projtype,'')
  let nsecs_s .= ' _vim_ '

  let nsecs_s = input('Sections to be created:',nsecs_s)
  let nsecs = base#qw(nsecs_s)

  for sec in nsecs
     call projs#newsecfile(sec)
  endfor

  call projs#proj#git_add()
  
  call base#echoredraw('Created new project: ' . proj)
  
  call base#varset('proj',proj)
  
  call projs#listadd(proj)
  
  let loadmain=input('Load the main project file? (1/0): ', 1)
  if loadmain 
    VSECBASE _main_
  endif
  
  TgUpdate projs_this
  call projs#update('list')

  call base#echoprefixold()
    
  return 1

endf

function! projs#pylib ()
	let pylib = base#qw#catpath('plg','projs python lib')
	return pylib
endfunction

"" projs#selectproject ()
"" projs#selectproject (pat)

function! projs#selectproject (...)
    
    if a:0
        let pat  = a:1
    endif

    let list = projs#list()

    let proj=base#getfromchoosedialog({ 
        \ 'list'        : list,
        \ 'startopt'    : '',
        \ 'header'      : "Available projects are: ",
        \ 'numcols'     : 1,
        \ 'bottom'      : "Choose a project by number: ",
        \ })
    return proj
    
endfunction



function! projs#viewproj (...)

    call projs#rootcd()

     """ delete buffers from the previously loaded project
     "RFUN DC_Proj_BufsDelete
     "BuffersWipeAll

    let sec = ''
    if a:0
        let proj = matchstr(a:1,'^\zs\w\+\ze')
        let sec  = matchstr(a:1,'^\w\+\.\zs\w\+\ze')
    else
        let proj=projs#selectproject()
    endif
    let proj = proj

    if !projs#exists(proj)
        let o = input('Project '.proj.' does not exist, create new? (1/0):',1)
        if o
            call projs#new(proj)
            return 1
        endif
    endif

    call projs#proj#name(proj)

    let f = projs#secfile('_osecs_')
    call projs#varset('secorderfile',f)

    if ! strlen(sec)
        let sec='_main_'
    endif


    call projs#varset('secname',sec)
    call projs#varset('proj',proj)
    
    call projs#opensec(projs#varget('secname',sec))
 
    if (exists("*make#makeprg"))
        call make#makeprg('projs_latexmk',{ 'echo' : 0 })
    endif

    let vimf = projs#path([ proj . '.vim' ])
    if filereadable(vimf)
        call projs#echo('Found project vim file, executing:' . "\n\t".vimf)
        exe 'source ' . vimf
    endif

    TgSet projs_this
    TgAdd plg_projs

    let loaded=projs#varget('loaded',[])

    call add(loaded,proj)
    call projs#varset('loaded',loaded)

    let u='piclist secnames usedpacks'
    call projs#update_qw(u)

endfun

fun! projs#complete (...)

  let comps=[]
  let comps=projs#list()

  return join(comps,"\n")
endf


fun! projs#checksecdir()

    call projs#varset('secdirexists',0)

    let proj = projs#var('proj')
    let dir  = projs#path([ proj ])

    if isdirectory(dir)
        call projs#var('secdirexists',1)
    endif

endf

function! projs#insert (...)
  let ins = get(a:000,0,'')

  let sub = 'projs#insert#'.ins
  "if exists("*".sub)
    exe 'call '.sub.'()'
  "endif
  
endfunction

function! projs#htlatex (...)
    call projs#build#run({ "opt" : 'build_htlatex' })
endfunction

function! projs#action (...)
  let act = get(a:000,0,'')

  let sub = 'projs#action#'.act

  exe 'call '.sub.'()'

endfunction

function! projs#switch (...)

  let proj = ''
  if a:0
    let proj = a:1
  else
    let proj = input('Switch to:','','custom,projs#complete#switch')
  endif

  "let ul = input('Update list? (1/0):',0)
  "if ul | call projs#update('list') | endif
  "
  setlocal iminsert=0

  while ! projs#exists(proj)
    let proj = input('Switch to:','','custom,projs#complete#switch')
    if proj == ''
      let text = 'Project switching aborted'
      redraw!
      call base#echo({ "text": text, "hl" : 'MoreMsg'})
      return
    endif
  endw

  call projs#proj#name(proj)
  let u='piclist secnames usedpacks'
  call projs#update_qw(u)

  let sec = 'body'
  let sec = input('Section to open:',sec,'custom,projs#complete#secnames')

  call projs#opensec(sec)
  
endfunction

"call projs#onload ()
"call projs#onload ({ 'proj' : proj })

function! projs#onload (...)
  let ref = {}
  if a:0 | let ref = a:1 | endif

  let prf={ 'prf' : 'projs#onload' }
  call base#log([
    \ 'ref => ' . base#dump(ref),
    \ ],prf)

  let b:projs_onload_done=1

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  setlocal ts=2

  "-------- needed for keymapping
  setlocal iminsert=0

  "-------- needed for tags
  setlocal isk=@,48-57,_,128-167,224-235

  TgSet projs_this

  StatusLine projs

	call projs#exe_latex('pdflatex')

  call projs#maps()

	let vf = projs#secfile('_vim_')
	call base#vimfile#source({ 'files' : [vf] })

endfunction

function! projs#exe_latex (...)
	let exe_latex = get(a:000,0,'pdflatex')

	let makeprg = make#varget('makeprg','projs_single_run')

	if a:0
		call projs#varset('exe_latex',exe_latex)
		call make#makeprg(makeprg)
	else
		let exe_latex = projs#varget('exe_latex',exe_latex)
	endif
	
 return exe_latex

endfunction

function! projs#opensec (...)
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
    let vfile = projs#secfile(sec) 
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

    let vfile = projs#secfile(sec)
  endif

  if strlen(vfile) 
    call add(vfiles,vfile)
  endif

  call projs#varset('curfile',vfile)

  let vfiles = base#uniq(vfiles)

	call projs#varset("parent_sec",parent_sec)

  for vfile in vfiles
    if !filereadable(vfile)
        call projs#newsecfile(sec)
    endif
    call base#fileopen(vfile) 
  endfor


  call base#stl#set('projs')
  "KEYMAP russian-jcukenwin
  KEYMAP ukrainian-jcuken

  return 
endf
    

function! projs#gensecdat (...)
 
 let f = projs#path([ proj . '.secs.i.dat' ])
 call projs#varset('secdatfile',f)

 let datlines=[]

 for line in projs#var('secnames')
   if ! base#inlist(line,base#qw("_main_ _dat_ _osecs_ _bib_ _pl_ "))
      call add(datlines,line)
   endif
 endfor

 call writefile(datlines,projs#varget('secdatfile'))

endf

fun! projs#opensecorder()
 
  let f = projs#path([proj . '.secorder.i.dat' ])

  call projs#varset('secorderfile',f)
  exe 'tabnew ' . projs#var('secorderfile')

  MakePrg projs

endf

 
"" Remove the project 
""  This function does not affect the current value of proj 
""          if proj is different from the project being removed.
""          On the other hand, if proj is the project requested to be removed,
""     proj is unlet in the end of the function body

" former DC_PrjRemove


function! projs#initvars (...)
    call base#plg#loadvars('projs')
    let vars = projs#varget('vars',{})

    for [k,v] in items(vars)
      call projs#varset(k,v)
    endfor
endf

function! projs#warn (text)
    let prefix = "--PROJS--"
    call base#warn({ "text" : a:text, "prefix" : prefix })
    
endfunction

function! projs#echo(text,...)

    let prefix='--PROJS--'
    if a:0
        let opts=a:1
        let prefix=get(opts,'prefix',prefix)
    endif

    call base#log(prefix . ' ' . a:text)

endfunction

function! projs#info ()

    let g:hl      = 'MoreMsg'
    let indentlev = 2
    let indent    = repeat(' ',indentlev)
    let prefix=''

    call base#echoprefix(prefix)

    let proj     = projs#var('proj')
    let secname  = projs#var('secname')
    let secnames = projs#proj#secnames()

    call projs#update('loaded')
        
    call base#echo({ 'text' : "PROJECTS ", 'hl' : 'Title' } )

    call base#echo({ 'text' : "Projects directory: " } )
    call base#echo({ 
        \ 'text' : "projs#root()     => " . projs#root(),
        \ 'indentlev' : indentlev, })

    call base#echo({ 
        \ 'text' : "projs#rootid()   => " . projs#rootid(),
        \ 'indentlev' : indentlev, })

    call base#echo({ 
        \ 'text' : "$PROJSDIR => " . base#envvar('PROJSDIR'), 
        \ 'indentlev' : indentlev, })

    call base#echo({ 'text' : "Projects PDF dir: " } )
    call base#echo({ 
        \ 'text' : "pdffin => " . projs#var('pdffin'),
        \ 'indentlev' : indentlev, })

    call base#echo({ 'text' : "Project type: " } )
    call base#echo({ 
        \ 'text'      : "projtype => " . projs#varget('projtype',''),
        \ 'indentlev' : indentlev, })
    
    call base#echo({ 'text' : "Current project: " } )
    call base#echo({ 
        \ 'text' : "proj => " . proj, 
        \ 'indentlev' : indentlev, })
    
    call base#echo({ 'text' : "Current section: " } )
    call base#echo({ 
        \ 'text' : "secname => " . secname, 
        \ 'indentlev' : indentlev })

    call base#echo({ 'text' : "Loaded projects: " } )
    let loaded=projs#var('loaded')
    call base#echo({ 
        \ 'text' : "loaded => " . base#dump(loaded), 
        \ 'indentlev' : indentlev })

    let cnt = input('Continue? (1/0): ',0)
  if !cnt | return | endif

    let cnt = input('Show list of sections? (1/0): ',1)
    if cnt
        call base#echo({ 'text' : "Sections: " } )
        call base#echo({ 
            \ 'text' : "secnames => " . "\n\t" . join(secnames,"\n\t"), 
            \ 'indentlev' : indentlev })
    endif

    call projs#checksecdir()

    let vvs = 'texoutdir texmode prjmake_opt secnamesbase pdfout'
    let vv  = base#qw(vvs)

    let cnt = input('Show Values for variables '.vvs.' ? (1/0): ',1)

    if cnt
        for v in vv
            if exists("vl") | unlet vl | endif
            let vl = projs#var(v)
    
            if base#type(vl) == 'List'
                let str = "\n\t" . join(vl,"\n\t")
            else
                let str = vl
            endif
            call base#echo({ 'text' : v . " => " . str  } )
        endfor
    endif

  return

endf

" call projs#filejoinlines ()
" call projs#filejoinlines ({ "sec" : sec })

function! projs#filejoinlines (...)
    let ref = {}
    if a:0 | let ref = a:1 | endif

    let sec = get(ref,'sec','_main_')

    let proj = projs#proj#name()
    call projs#rootcd()

    """ jfile handling ----------------------
    let jdir = projs#path(['joins'])
    call base#mkdir(jdir)
    let jfile = base#file#catfile([ jdir, proj . '.tex' ])
    let jfile = get(ref,'jfile',jfile)

    let write_jfile = get(ref,'write_jfile',0)
    """ end jfile handling ----------------------

    let sf      = {}
    let sf[sec] = projs#secfile(sec)
    let f       = sf[sec]

    if !filereadable(f)
      return []
    endif

    let flines = readfile(f)
    let lines  = []

    let pats={
        \ 'ii'    : '^\s*\\ii{\(\w\+\)}.*$',
        \ 'iifig' : '^\s*\\iifig{\(\w\+\)}.*$',
        \ 'input' : '^\s*\\input{\(.*\)}.*$',
        \   }

    let delim=repeat('%',50)

    for line in flines
        if line =~ pats.ii

            let iisec   = substitute(line,pats.ii,'\1','g')

            let iilines = projs#filejoinlines({ "sec" : iisec })

            call add(lines,delim)
            call add(lines,'%% ' . line)
            call add(lines,delim)

            call extend(lines,iilines)

        elseif line =~ pats.iifig

            let fsec = substitute(line,pats.iifig,'\1','g')
            let fsec = 'fig.'.fsec

            let figlines=projs#filejoinlines({ "sec" : fsec })

            call add(lines,delim)
            call add(lines,'%% ' . line)
            call add(lines,delim)

            call extend(lines,figlines)

        elseif line =~ pats.input

            let if = substitute(line,pats.input,'\1','g')
        else
            call add(lines,line)
        endif
    endfor

    if sec == '_main_'

        if write_jfile
          echo 'Writing joined lines into: ' 
          echo '  ' . jfile
      
          call writefile(lines,jfile)
        endif

    endif

    return lines

endf

function! projs#maps ()
    nnoremap <silent> ;;co :copen<CR>
    nnoremap <silent> ;;cc :cclose<CR>

      nnoremap <buffer><silent> ;mm :PrjMake<CR>
      nnoremap <buffer><silent> ;mp :PrjMake build_pdflatex<CR>
      nnoremap <buffer><silent> ;ms :PrjMake single_run<CR>
      nnoremap <buffer><silent> ;ml :PrjMake latexmk<CR>
      nnoremap <buffer><silent> ;rt :exe "set et | retab"<CR>
      nnoremap <buffer><silent> ;v  :PrjPdfView<CR>
      nnoremap <buffer><silent> ;tg :TgUpdate<CR>
      nnoremap <buffer><silent> ;o  :OMNIFUNC<CR>

      nnoremap <buffer><silent> ;sw :PrjSwitch<CR>

      nnoremap <buffer><silent> <F1> :PrjMake build_pdflatex<CR>
      nnoremap <buffer><silent> <F2> :PrjMake single_run<CR>
      nnoremap <buffer><silent> <F3> :PrjMake latexmk<CR>
      nnoremap <buffer><silent> <F4> :PrjMake<CR>
      nnoremap <buffer><silent> <F5> :PrjMakePrompt<CR>
  
      nnoremap <buffer><silent> <F6> :PrjSwitch<CR>
      nnoremap <buffer><silent> <F7> :PrjPdfView<CR>
      nnoremap <buffer><silent> <F8> :PrjUpdate<CR>
      nnoremap <buffer><silent> <F9> :OMNIFUNC<CR>
      nnoremap <buffer><silent> <F10> :TgUpdate<CR>

    nnoremap <buffer><silent> <C-S> :GitSave<CR>
    
endfunction

function! projs#builddir (...)
    let proj     = projs#proj#name()
    let broot    = projs#varget('rootbuilddir','')
    let builddir = base#file#catfile([ broot, proj ])

    return builddir
endfunction

"""projs_init

"call projs#init ()       -  ProjsInit     - use environment variable PROJSDIR
"call projs#init (dirid)  -  ProjsInit DIRID - specify custom projects' directory, full path is base#path(DIRID)
"
"
" ProjsInit DIRID

function! projs#init (...)

    " -------------------------------------------------
    " load variables from the corresponding dat files
    " load: 
    "   data/list/vars.i.dat
    "
    "   all other dat files in data/list, data/dict subdirs
    call projs#initvars()
    " -------------------------------------------------

    " plg_projs augroup - autocommand group
    call projs#init#au()

    " init projs variables: 
    "   templates_tex, templates_vim
    call projs#init#templates()

    let rootid = projs#varget('rootid','')
    let rootid = get(a:000,0,rootid)

    let [root,rootid] = projs#init#root(rootid)

    if !strlen(rootid)
      call projs#warn('rootid is NOT defined! Aborting init.')
      return
    endif

    "call base#cd(root)

    let ifile = projs#path(['_init_.vim'])
    if filereadable(ifile)
      exe 'so '.ifile
    endif

    let prefix="(projs#init) "
    call projs#echo("Initializing projs plugin, \n\t projsdir => " . root ,{ "prefix" : prefix })
  
    let pdfout = projs#path([ 'pdf_built' ])

    let pdffin = exists('$PDFOUT') ? $PDFOUT : base#qw#catfile('C: out pdf')

    call projs#varset('pdffin',pdffin)
    call base#mkdir(pdffin)

    call projs#varset('prjmake_opt','latexmk')

    call projs#varset('pdfout',pdfout)
    call base#mkdir(pdfout)

    let rootbuilddir = projs#path([ 'builds' ])
    call projs#varset('rootbuilddir',rootbuilddir)
    call base#mkdir(rootbuilddir)

    if ! exists("proj") | let proj='' | endif
        
    let projsdirs = projs#varget('projsdirs')
    call projs#varset('projsdirslist',projsdirs)

    call projs#varset('exe_latex','pdflatex')

    " update list of projs plugin variables
    call projs#update#varlist()

    " update list of projects
    call projs#update('list')

    "MenuAdd projs

endfunction

function! projs#listwrite2dat (...)

 call base#echoprefix("(projs#listwrite2dat) " )

 if a:0
    let list = a:1
    if base#type(list) != 'List'
        call base#warn({ "text" : "1st input parameter should of type List" })
        return 0
    endif
 else
    let list = projs#list()
 endif

 let dfile = projs#path([ 'PROJS.i.dat' ])
 call writefile(list,dfile)
    
endfunction

" get the value of root dir
" set the value of root dir

function! projs#root (...)
    if a:0
        let root = a:1
        call projs#var('root',root)
    endif
    return projs#var('root')
endf    

function! projs#rootid ()
    return projs#varget('rootid','')
endf  

function! projs#rootbasename ()
    let root = projs#root()
    let bn   = fnamemodify(root,":p:h:t")

    return bn
endf    

function! projs#rootcd ()
    let dir =  projs#root()
    exe 'cd ' . dir
endf    

function! projs#plgdir ()
    return projs#var('plgdir')
endf    

function! projs#datadir ()
    return projs#var('datadir')
endf    

function! projs#plgcd ()
    let dir = projs#plgdir()
    exe 'cd ' . dir
endf    

function! projs#listfromdat ()
    let file = projs#list_dat()
    let list = base#readdatfile({ 
            \ "file" : file, 
            \ "type" : "List", 
            \ "sort" : 1,
            \ "uniq" : 1,
            \ })
    call projs#var("list",list)
    return list
endf    

function! projs#list_dat ()
    let file = ap#file#catfile([ projs#root(), 'PROJS.i.dat' ])
endfunction

function! projs#list_write2dat ()
    let file = projs#list_dat()
    let list = projs#var("list",[])

    if !len(list)
      call projs#listfromfiles()
    endif
endfunction

function! projs#listfromfiles ()
    let root = projs#root()

    let list = base#find({ 
        \ "dirs" : [ root ]                  ,
        \ "ext"  : [ "tex" ]                 ,
        \ "relpath" : 1                      ,
        \ "subdirs" : 0                      ,
        \ "pat"     : '^(\w+)\.tex$'         , 
        \ })
        
    let exclude=projs#list#exclude()

    let nlist=[]
    let found={}
    for p in list
        let p = substitute(p,'^\(\w\+\)\.tex$','\1','g')

        if base#inlist(p,exclude)
            continue
        endif

        if !get(found,p,0)
            call add(nlist,p)
            let found[p]=1
        end
    endfor

    call projs#varset('list',nlist)

    return nlist
endf    

function! projs#piclist ()
  let list = projs#varget('piclist',[])
  return list
endf    

"let list = projs#list ()
"let list = projs#list ({ 'get' : 'fromfiles' })
"let list = projs#list ({ 'get' : 'fromvar' })

function! projs#list (...)
    let refdef={ 
          \ 'get' : 'fromvar'
          \ }
    let ref  = refdef
    let refa = get(a:000,0,{})

    call extend(ref,refa)

    let gt = get(ref,'get')
    while 1
      if gt == 'fromvar'
        let list = projs#varget('list',[])
        if ! len(list) 
          let gt = 'fromfiles' 
          continue
        endif
      elseif gt == 'fromfiles'
        let list = projs#listfromfiles()
      endif
      break
    endw

    return copy(list)
endf    

function! projs#listadd (proj)
    let list = projs#list()

    if ! projs#ex(a:proj)
        call add(list,a:proj)
    endif

    call projs#varset("list",list)
    
endfunction

function! projs#ex (proj)

    let list = projs#list()
    if index(list,a:proj) >= 0
        return 1
    endif

    return 0

endfunction

function! projs#pathqw (s)
    let pa = base#qw(a:s)
    return projs#path(pa)

endfunction

function! projs#pathqwrf (s)
    let pa = base#qw(a:s)
    let f = projs#path(pa)
    let lines = []


    if filereadable(f)
        let lines = readfile(f)
    endif

    return lines

endfunction




"""projs_path
"
"
"" projs#path(['a', 'b'])
"" projs#path(base#qw('a b'))

function! projs#path (pa)
    let root = projs#root()
    let arr = [ root ]
    call extend(arr,a:pa)

    let fullpath = base#file#catfile(arr)

    return fullpath
    
endfunction

function! projs#vars (...)
  let vars =  base#varget('projs_vars',{})
  return vars
endfunction

function! projs#varlist (...)
  let vars = projs#var('varlist')
  return vars
endfunction

function! projs#var (...)
    if a:0 == 1
        let var = a:1
        return base#varget('projs_'.var)
    elseif a:0 == 2
        let var = a:1
        let val = a:2
        return base#varset('projs_'.var,val)
    endif
endfunction


function! projs#varset (varname, value)
  call base#varset('projs_'.a:varname,a:value)
endfunction

function! projs#varecho (varname)
    echo projs#varget(a:varname)
endfunction

function! projs#varget (varname,...)
    if a:0
      let val = base#varget('projs_'.a:varname,a:1)
    else
      let val = base#varget('projs_'.a:varname)
    endif
   
    return val
    
endfunction


function! projs#varexists (varname)
    if base#varexists('projs_'.a:varname)
        return 1
    endif
    return 0

endfunction

function! projs#varsetfromdat (varname,...)
    let datafile = projs#datafile(a:varname)

    if a:0
        let type = a:1
    else
        let type = "List"
    endif

    if !filereadable(datafile)
        call projs#warn('NO datafile for: ' . a:varname)
        return 0
    endif

    let data = base#readdatfile({ 
        \   "file" : datafile ,
        \   "type" : type ,
        \   })

    call projs#var(a:varname,data)

    return 1

endfunction


function! projs#datafile (id)
    let files = projs#datafiles(a:id)
    let file = get(files,0,'')
    return file
endfunction

function! projs#datafiles (id)
    let datadir = projs#datadir()
    let file = a:id . ".i.dat"

    let files = base#find({
        \ "dirs"    : [ datadir ],
        \ "subdirs" : 1,
        \ "pat"     : '^'.file.'$',
        \   })

    return files
endfunction



 
function! projs#renameproject(old,new)

 let old = a:old
 let new = a:new

 call projs#rootcd()
 call projs#proj#name(old)

 let files = projs#proj#files({ "exts" : [] })

 call projs#proj#name(new)
 
 for f in files
    let nf = substitute(f,'^'.old,new,'g')
    call rename(f,nf)

    let bn = fnamemodify(nf,':p:t')
    let sec = projs#secfromfile({ "file" : bn })
    if sec == '_main_'
        let lines=readfile(nf)
        let nlines=[]
        let changed=0
        for line in lines
            if line =~ '^\def\PROJ{'.old.'}'
                let line = '\def\PROJ{'.new.'}'
                let changed = 1
            endif
            call add(nlines,line)
        endfor
        if changed
            call writefile(nlines,nf)
        endif
    endif
 endfor

 call projs#update('list')
 
endfunction

""used in:
""  projs#new

function! projs#genperl(...)

 let pmfiles={}
 let proj = projs#var('proj')

 call extend(pmfiles, {
            \   'generate_pm' : g:paths['perlmod'] . '/lib/TeX/Project/Generate/' . proj . '.pm',  
            \   'generate_pl' : g:paths['projs']  . '/generate.' . proj . '.pl',  
            \   })
 
endfunction

function! projs#prjmakeoption (...)
    if a:0
        let opt = a:1
    else
        "let opt = 'latexmk'
        if projs#varexists('prjmake_opt')
            let opt  = projs#varget('prjmake_opt','')
        else
            let opts = projs#varget('prjmake_opts',[])
            let opt  = base#getfromchoosedialog({ 
                \ 'list'        : opts,
                \ 'startopt'    : 'regular',
                \ 'header'      : "Available options for projs#build#run(...) are: ",
                \ 'numcols'     : 1,
                \ 'bottom'      : "Choose an option by number: ",
                \ })
        endif
        call projs#varset('prjmake_opt',opt)
    endif
    return opt
endfunction

function! projs#prjmake (...)
    let opt = a:0 ? a:1 :  projs#prjmakeoption()
    call projs#build#run({ "opt" : opt })
endfunction
    " -------------------------------------------------

function! projs#prjmakeprompt (...)
    let opt = a:0 ? a:1 :  projs#prjmakeoption()
    call projs#build#run({ "opt" : opt, "prompt" : 1 })
endfunction

function! projs#buildnum (...)
 if a:0
    let proj = a:1
 else
    let proj = projs#proj#name()
 endif

 let prf={ 'prf' : 'projs#buildnum' }
 call base#log([
  \ 'proj => ' . proj ,
  \ ],prf)
        
 """" --------------------- get build number, initialize output pdf directory
 let pdfout = projs#path([ 'pdf_built' ])
 call base#mkdir(pdfout)

 let bnum = 1
 let pdfs = base#find({ 
    \ "dirs" : [ pdfout ], 
    \ "exts" : ["pdf"],
    \ "relpath" : 1,
    \ "pat"     : '^'.proj.'(\d+)\.pdf',
    \ })

 let bnums = []
 let pat = proj.'\(\d\+\)\.pdf'
 for pdf in pdfs
    if pdf =~ pat
        let bnum = substitute(pdf,pat,'\1','g')
        call add(bnums,str2nr(bnum))
    else
        continue
    endif
 endfor

 func! Cmp(i1, i2)
   return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
 endfunc

 let bnums = sort(bnums,"Cmp")

 if len(bnums)
    let bnum = bnums[-1] + 1
 else
    let bnum = 1
 endif
 let snum = bnum . ''

 """" ---------------------
 return snum
    
endfunction

function! projs#setbuildvars (...)
 let ref = {}
 if a:0 | let ref = a:1 | endif

 let prf={ 'prf' : 'projs#setbuildvars' }
 call base#log([
  \ 'ref => ' . base#dump(ref),
  \ ],prf)
        
 let proj = projs#proj#name()

 let bnum      = projs#buildnum()
 let texoutdir = base#file#catfile([ projs#builddir(), bnum ])

 call base#mkdir(texoutdir)
 call projs#varset('texoutdir',texoutdir)

 let texmode    = projs#varget('texmode')
 let texjobname = proj

 let buildmode    = projs#varget('buildmode','')

 call projs#varset('texjobname',texjobname)
 call projs#varset('buildnum',bnum)

  let txt =''
  let txt.= "\n" . '---------- projs#setbuildvars(...)--------'
  let txt.= "\n" . 'Setting latex build-related options:'
  let txt.= "\n" . ' '
  let txt.= "\n" . '  buildnum         => '  . bnum
  let txt.= "\n" . '  texjobname       => '  . texjobname
  let txt.= "\n" . '  texmode          => '  . texmode
  let txt.= "\n" . ' '
  let txt.= "\n" . '  buildmode        => '  . buildmode
  let txt.= "\n" . ' '
  let txt.= "\n" . '---------- end projs#setbuildvars---------'

  let prf={ 'prf' : '' }
  let log = split(txt,"\n")

  call base#log(log,prf)
    
endfunction

function! projs#git (...)
    call projs#rootcd()
    
endfunction

function! projs#grep (...)
    let ref = {}

    if a:0 
      let pat = a:1
      if a:0 > 1 | let ref = a:2 | endif
    else
      let pat = input('Pattern to search for:','')
    endif

    call projs#rootcd()

    let exts  = base#qw('tex vim bib')
    let files = projs#proj#files ({ "exts" : exts })

    call base#grep({ 
        \ "pat"   : pat   ,
        \ "files" : files ,
        \ })
    
endfunction

function! projs#update_qw (s)
  let s = a:s 
  let opts = base#qwsort(s)

  for o in opts
    call projs#update(o)
  endfor

endfunction

function! projs#update (...)
  let opts = projs#varget('opts_PrjUpdate',base#qw('secnames list datvars'))
  let proj = projs#proj#name()

  if a:0
       let opt = a:1
  else
       let opt = base#getfromchoosedialog({ 
            \ 'list'        : opts,
            \ 'startopt'    : 'regular',
            \ 'header'      : "Available options are: ",
            \ 'numcols'     : 1,
            \ 'bottom'      : "Choose an option by number: ",
            \ })
    endif

    let o = { "prefix" : "(proj: ".proj.") "  }

"""prjupdate_secnames
    if opt == 'secnames'
        call projs#echo("Updating list of sections",o)

        call projs#proj#files({ 'rw_f_listfiles' : 1 })

        call projs#proj#secnames()
        call projs#proj#secnamesall()

    elseif opt == 'list'
        call projs#echo("Updating list of projects")

        call projs#listfromfiles()


"""prjupdate_piclist
    elseif opt == 'piclist'
        call projs#echo("Updating list of pictures",o)

        let pdir = projs#path(['pics',proj])
        let piclist = base#find({ 
            \ "dirs"    : [pdir],
            \ "qw_exts" : 'jpg png eps',
            \ "rmext" : 1,
            \ "relpath" : 1,
            \ })
        call projs#varset('piclist',piclist)

"""projsupdate_listfiles
    elseif opt == 'listfiles'
        call projs#proj#files({ 'rw_f_listfiles' : 1 })

    elseif opt == 'secnamesbase'
        call projs#echo("Updating list of base sections",o)

        call projs#varsetfromdat('secnamesbase')

    elseif opt == 'usedpacks'
        call projs#echo("Updating list of used TeX packages",o)

        call projs#update#usedpacks()

    elseif opt == 'varlist'
        call projs#echo("Updating list of PROJS variables")

        call projs#update#varlist()

    elseif opt == 'datvars'
        call projs#update#datvars()

    elseif opt == 'loaded'
        call projs#echo("Updating list of loaded projects")

        call base#buffers#get()
    
        let bufs=base#var('bufs')
        let loaded={}
    
        for b in bufs
          let file = get(b,'shortname','')
          let path = get(b,'path','')
          let ext  = get(b,'ext','')
    
          if path != projs#root() | continue | endif
    
          let proj = projs#namefromfile({ 'file' : file })
          call extend(loaded,{ proj : 1 })
        endfor
        call projs#var('loaded',keys(loaded))

    endif
    
endfunction


function! projs#load (...)

    if a:0
        let opt = a:1
    endif

    if opt == ''
    elseif opt == 'tex'
        ProjsInit
        PrjView TEXREF
        PrjView latexref
    elseif opt == 'paps_phd'
    endif
    
endfunction

function! projs#exists (...)
    let proj = a:1
    let list = projs#list()

    if base#inlist(proj,list)
        return 1
    endif

    return 0
    
endfunction

