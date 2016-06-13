
function! projs#newseclines#single_file#_main_ (...)

    let lines = []

    let proj = projs#proj#name()
    
    call add(lines,' ')
    call add(lines,'%%file f_main')
    call add(lines,' ')
    call add(lines,'\def\PROJ{'.proj.'}')
    call add(lines,' ')
    call add(lines,'\def\ii#1{\InputIfFileExists{\PROJ.#1.tex}{}{}}')
    call add(lines,' ')

    call add(lines,' ')
    call add(lines,'\begin{document}')
    call add(lines,' ')
    call add(lines,'\end{document}')
    call add(lines,' ')
    
    return lines
          
endfunction
