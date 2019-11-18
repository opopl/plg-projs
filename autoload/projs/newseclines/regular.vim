
"		called by:
"			projs#sec#new
"
function! projs#newseclines#regular#_main_ (...)

    let lines = []

    let proj = projs#proj#name()
    
    call add(lines,' ')
    call add(lines,'%%file f_main')
    call add(lines,' ')
    call add(lines,'\def\PROJ{'.proj.'}')
    call add(lines,'\def\ii#1{\InputIfFileExists{\PROJ.#1.tex}{}{}}')
    
    call add(lines,' ')
    
    call add(lines,'\ii{preamble}')
    call add(lines,'\ii{defs}')
    call add(lines,' ')
    
    call add(lines,'\begin{document}')
    call add(lines,'\ii{body}')
    call add(lines,'\end{document}')
    call add(lines,' ')
    
    return lines
          
endfunction

function! projs#newseclines#regular#listfigs (...)
	let lines = []

	call add(lines,' ')
	call add(lines,'\phantomsection')
	call add(lines,' ')
	call add(lines,'\addcontentsline{toc}{chapter}{\listfigurename} ')
	call add(lines,' ')
	call add(lines,'\listoffigures')
	call add(lines,'\newpage')
	call add(lines,' ')

	return lines
endfunction

function! projs#newseclines#regular#listtabs (...)
	let lines = []

	call add(lines,' ')
	call add(lines,'\phantomsection')
	call add(lines,' ')
	call add(lines,'\addcontentsline{toc}{chapter}{\listtablename} ')
	call add(lines,' ')
	call add(lines,'\listoftables')
	call add(lines,'\newpage')
	call add(lines,' ')

	return lines
endfunction

function! projs#newseclines#regular#title ()
	let lines = []

  call add(lines,' ')
  call add(lines,'\begin{titlepage}')
  call add(lines,' ')
  call add(lines,'\end{titlepage}')

	return lines
endfunction

function! projs#newseclines#regular#cfg ()
	let lines = []
	call extend(lines, tex#lines('tex4ht_cfg') )
	return lines
endfunction

function! projs#newseclines#regular#preamble ()
	let lines = []

	let packs = projs#varget('tex_packs_preamble',[])
	
	let packopts = {
	    \ 'fontenc'  : 'OT1,T2A,T3',
	    \ 'inputenc' : 'utf8',
	    \ }
	
	let ln  = projs#qw#rf('data tex preamble.tex')
	call extend(lines,ln)
	return lines
endfunction

function! projs#newseclines#regular#index ()
	let lines = []

  call add(lines,'\clearpage')
  call add(lines,'\phantomsection')
  call add(lines,'\addcontentsline{toc}{chapter}{\indexname}')
  call add(lines,'\printindex')

	return lines
endfunction

function! projs#newseclines#regular#bib (inref)
	let lines = []

  let bibstyle = base#input('Bibliography style:','unsrt',a:inref)
  let bibfile  = base#input('Bibliography:','\PROJ.refs',a:inref)

  call add(lines,'\phantomsection')

  call add(lines,'\addcontentsline{toc}{chapter}{\bibname}')

  call add(lines,'\bibliographystyle{'.bibstyle.'}')
  call add(lines,'\bibliography{'.bibfile.'}')

	return lines
endfunction

function! projs#newseclines#regular#_pl_ ()
	let lines = []

"perl << eof
   "use Vim::Perl qw(:funcs :vars);

   "my $proj  = VimVar('proj');
   "my $lines = [];

   "push @$lines,map { s/^\s*//g; $_} split "\n" => qq{
     "use strict;
     "use warnings;
     "use utf8;

     "use Data::Dumper;
     "use FindBin qw(\$Bin \$Script);

     "my \$proj=\"$proj\";
   "};

   "VimListExtend('lines',$lines);
"eof
	"return lines

endfunction

function! projs#newseclines#regular#_build_htlatex_(...)
	let ref  = get(a:000,0,{})

	let proj = get(ref,'proj','')

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

	let lines = []
	
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

	return lines
endfunction

function! projs#newseclines#regular#_main_htlatex_(...)
	let ref = get(a:000,0,{})

	let sec = get(ref,'sec','')

	let lines = []
	
	call add(lines,' ')
	call add(lines,'%%file '. sec)
	call add(lines,' ')
	call add(lines,'\nonstopmode')
	call add(lines,' ')
	
	let mf = projs#sec#file('_main_')
	let ml = readfile(mf)
	
	call filter(ml,'v:val !~ "^%%file f_main"')
	
	call extend(lines,ml)

	return lines
endfunction

function! projs#newseclines#regular#_dat_files_(...)
	let lines = []

	let files = projs#proj#files()
	call extend(lines,files)

	return lines
endfunction
