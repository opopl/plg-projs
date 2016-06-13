function! projs#select#projtype ()
        
 let projtype = base#getfromchoosedialog({ 
            \ 'list'        : projs#varget('projecttypes',[]),
            \ 'startopt'    : 'regular',
            \ 'header'      : "Available project types are: ",
            \ 'numcols'     : 1,
            \ 'bottom'      : "Choose a project type by number: ",
            \ })
 return projtype

endfunction

function! projs#select#projstruct ()

 let projstruct = base#getfromchoosedialog({ 
            \ 'list'        : projs#varget('projectstructures',[]),
            \ 'startopt'    : 'in_root',
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

