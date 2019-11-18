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

function! projs#select#keymap ()

    let keymap = 'russian-jcukenwin'
    let keymap = input('Keymap:',keymap,'custom,txtmy#complete#keymap')
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

