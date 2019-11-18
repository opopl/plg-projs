
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
	return lines

endfunction
