
call projs#init#cmds()

command! -nargs=0 CitnTexToDat call s:CitnTexToDat()
command! -nargs=0 CitnDatToTex call s:CitnDatToTex()
command! -nargs=0 CitnDatView  call s:CitnDatView()

function! s:CitnDatView ()
  let proj = projs#proj#name()
  let datf = projs#path([proj . '.citn.i.dat' ])

  call base#fileopen({ "files" : [ datf ] })
endf

function! s:CitnTexToDat ()
  let proj = projs#proj#name()
  let texf = projs#sec#file('citn')

  if !filereadable(texf)
    return
  endif

  let datf  = projs#path([proj . '.citn.i.dat' ])
  let lines = readfile(texf)

  let pat = '^\s*\\ifthenelse{\\equal{#1}{\(\d\+\)}}{\\cite{\(.*\)}}{}.*$'

  let datlines=[]

  for line in lines
    if line =~ pat
      let num = substitute(line,pat,'\1','g')
      let key = substitute(line,pat,'\2','g')
      let nline = num . ' ' .key
      call add(datlines,nline)
    endif
  endfor

  echo 'Writing citn.i.dat file:'
  echo ' ' . datf

  call writefile(datlines,datf)

endfunction

function! s:CitnDatToTex ()
  let proj = projs#proj#name()

  let datf  = projs#path([proj . '.citn.i.dat' ])

  if !filereadable(datf)
    return
  endif

  let texf = projs#sec#file('citn')

  let texlines = []

  call add(texlines,' ')
  call add(texlines,'%%file f_citn')
  call add(texlines,' ')
  call add(texlines,'\def\citn#1{%')
  call add(texlines,' ')

  let lines = readfile(datf)

  let pat ='^\(\d\+\)\s\+\(.*\)$'
  for line in lines
    if line =~ pat
      let num = substitute(line,pat,'\1','g')
      let key = substitute(line,pat,'\2','g')
      let x  = '  \ifthenelse{\equal{#1}{'.num.'}}{\cite{'.key.'}}{}%'
      call add(texlines,x)
    endif
  endfor

  call add(texlines,'}')

  echo 'Writing citn.tex file:'
  echo ' ' . texf

  call writefile(texlines,texf)

endfunction


