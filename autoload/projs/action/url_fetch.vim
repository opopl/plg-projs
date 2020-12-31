
function! projs#action#url_fetch#Fc ()

  let s:obj = {}
  function! s:obj.init (...) dict
    let ref = get(a:000,0,{})

    let ofile     = get(ref,'ofile','')
    let old_mtime = get(ref,'old_mtime','')

    let mtime = base#file#mtime(ofile)

    let ok = 0 

    """ file exists already
    if len(old_mtime) 
     if (str2nr(mtime) > str2nr(old_mtime) )
      let ok = 1
     endif
    else
      if filereadable(ofile)
        let ok = 1
      endif
    endif

    if ok
      call base#rdw('SUCCESS: URL FETCH')
    else
      call base#rdwe('FAIL: URL FETCH')
    endif

    "let cmd = printf('htw --file %s --cmd vh_convert',shellescape(ofile))
    let cmd = printf('links -dump -force-html -html-tables 1 %s',shellescape(ofile))

    let env = {}
    function env.get(temp_file) dict
      let code = self.return_code
    
      if filereadable(a:temp_file)
        let out = readfile(a:temp_file)
        "call base#buf#open_split({ 'lines' : out })
        call append('$',out)
      endif
    endfunction
    
    call asc#run({ 
      \  'cmd' : cmd, 
      \  'Fn'  : asc#tab_restore(env) 
      \  })

  endfunction
  
  let Fc = s:obj.init
  return Fc

endf

if 0
  call tree
    called by
      projs#action#url_fetch
endif

function! projs#action#url_fetch#url ()
    let url = ''
    let urls = [
        \ exists('b:url') ? b:url : '',
        \ projs#db#url(),
        \ projs#buf#url(),
        \ ] 
    echo urls

    while !strlen(url) && len(urls)
      let url = remove(urls,0)
      if strlen(url)
        break
      endif
    endw

    if !strlen(url)
      let url = projs#select#url()
      let b:url = url
      call projs#db#url_set({
        \ 'url' : url
        \   })

      call projs#sec#insert_url({ 
        \ 'url' : url, 
        \ 'sec' : projs#buf#sec() })
    endif
    return url

endf
