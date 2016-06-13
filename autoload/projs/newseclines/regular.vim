
function! projs#newseclines#regular#_main_ (...)

    let lines = []

    let proj = projs#proj#name()
    
    call add(lines,' ')
    call add(lines,'%%file f_main')
    call add(lines,' ')
    call add(lines,'\def\PROJ{'.proj.'}')
    call add(lines,' ')
    
    call add(lines,'% --------------')
    call add(lines,'\def\ii#1{\InputIfFileExists{\PROJ.#1.tex}{}{}}')
    call add(lines,'\def\iif#1{\input{\PROJ/#1.tex}}')
    call add(lines,'\def\idef#1{\InputIfFileExists{_def.#1.tex}{}{}}')
    call add(lines,'% --------------')
    
    let ProjRootSec = input('(_main_) ProjRootSec:','part','custom,projs#complete#projrootsec')
    
    call add(lines,'% --------------')
    call add(lines,'\def\ProjRootSec{'.ProjRootSec.'}')
    call add(lines,'% --------------')
    
    call add(lines,' ')
    
    call add(lines,'\ii{preamble}')
    call add(lines,' ')
    call add(lines,'%Definitions ')
    call add(lines,'\ii{defs}')
    call add(lines,' ')
    
    call add(lines,'\begin{document}')
    call add(lines,' ')
    call add(lines,'\ii{body}')
    call add(lines,' ')
    call add(lines,'%Bibliography ')
    call add(lines,'\ii{bib}')
    call add(lines,' ')
    call add(lines,'%Index ')
    call add(lines,'\ii{index}')
    call add(lines,' ')
    call add(lines,'\end{document}')
    call add(lines,' ')
    
    return lines
          
endfunction
