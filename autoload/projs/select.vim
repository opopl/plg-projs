function! projs#select#projtype ()
 let list  = projs#varget('projecttypes',[])
        
 let projtype = base#getfromchoosedialog({ 
            \ 'list'        : list,
            \ 'startopt'    : get(list,0,''),
            \ 'header'      : "Available project types are: ",
            \ 'numcols'     : 1,
            \ 'bottom'      : "Choose a project type by number: ",
            \ })
 return projtype

endfunction

function! projs#select#keymap (...)
  let ref = get(a:000,0,{})

  let prompt = get(ref,'prompt',0)

  let keymap = 'russian-jcukenwin'
  if prompt
    let keymap = input('Keymap:',keymap,'custom,txtmy#complete#keymap')
  endif
  return keymap
endfunction

function! projs#select#projstruct ()
 let list = projs#varget('projectstructures',[])

 let projstruct = base#getfromchoosedialog({ 
            \ 'list'        : list,
            \ 'startopt'    : get(list,0,''),
            \ 'header'      : "Available project structures are: ",
            \ 'numcols'     : 1,
            \ 'bottom'      : "Choose a project structure by number: ",
            \ })
 return projstruct
        
endfunction

function! projs#select#sec ()
        
    let sec='body'

    let listsecs = copy(projs#varget('secnamesbase',[]))
    call extend(listsecs,projs#proj#secnames())

    let listsecs=sort(base#uniq(listsecs))

    let sec = base#getfromchoosedialog({ 
        \ 'list'        : listsecs,
        \ 'startopt'    : 'body',
        \ 'header'      : "Available sections are: ",
        \ 'numcols'     : 1,
        \ 'bottom'      : "Choose section by number: ",
        \ })
    return sec

endfunction

function! projs#select#sec_input ()
  let msg_a = [
    \  "section: ",  
    \  ]
  let msg = join(msg_a,"\n")
  let sec = exists('b:sec') ? b:sec : ''
  let sec = base#input_we(msg,sec,{ 'complete' : 'custom,projs#complete#secnames' })
  return sec
endfunction
