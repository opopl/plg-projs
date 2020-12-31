
"see also: 
"
function! projs#sec#url#fetch (sec,...)
  let ref = get(a:000,0,{})

  let sec = a:sec

  let url = projs#db#url()
  let url = get(ref,'url',url)

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let ofile = projs#sec#url#local(sec)

  call base#rdw(ofile)

  let old_mtime = filereadable(ofile) ? base#file#mtime(ofile) : ''

  let Fc =  projs#sec#url#fetch_Fc ()

  let Fc_args = [{ 
    \ 'ofile'     : ofile,
    \ 'old_mtime' : old_mtime,
    \ }]

  call idephp#curl#run({ 
    \ 'url'         : url,
    \ 'insecure'    : 1 ,
    \ 'output_file' : ofile,
    \ 'Fc'          : Fc,
    \ 'Fc_args'     : Fc_args,
    \ })


endfunction

if 0
  call tree
    called by
      projs#sec#url#fetch
endif

function! projs#sec#url#fetch_Fc (...)
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

endfunction

function! projs#sec#url#local (sec,...)
  let sec = a:sec

  let ref = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let bname = join(filter([ proj, sec, 'html' ],'strlen(v:val) > 0' ), '.')

  let ofile = join([ projs#url_dir(), bname ], '/')
  call base#mkdir(projs#url_dir())

  return ofile

endfunction
