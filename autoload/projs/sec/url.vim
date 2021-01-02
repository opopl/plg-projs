
"see also: 
" projs#action#url_fetch
" pa_url_fetch
function! projs#sec#url#fetch (...)
  let ref = get(a:000,0,{})

  let sec = get(ref,'sec','')

  let url = projs#db#url()
  let url = get(ref,'url',url)

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let ofile = projs#sec#url#local(sec)
  let old_mtime = filereadable(ofile) ? base#file#mtime(ofile) : ''

  call base#rdw(ofile)

  let Fc =  projs#sec#url#fetch_Fc ({ 
    \ 'sec' : sec,
    \ })

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



function! projs#sec#url#dump_to_sec (...)
  let ref = get(a:000,0,{})

  let sec = get(ref,'sec','')
  let sec_file = projs#sec#file(sec)

  let ofile = projs#sec#url#local(sec)

  let cmd = printf('links -dump -force-html -html-tables 1 %s',shellescape(ofile))

  let env = { 'sec_file' : sec_file }
  function env.get(temp_file) dict
    let code = self.return_code

    let sec_file = get(self,'sec_file','')
    
    if filereadable(a:temp_file)
      let html_out = readfile(a:temp_file)
      call writefile(html_out,sec_file,'a')
    endif
  endfunction
    
  call asc#run({ 
      \  'cmd' : cmd, 
      \  'Fn'  : asc#tab_restore(env) 
      \  })
endf

if 0
  call tree
    called by
      projs#sec#url#fetch
  usage
    let Fc = projs#sec#url#fetch_Fc({ 'sec' : sec })
endif

" to be called after successful 'curl' run
function! projs#sec#url#fetch_Fc (...)
  let ref = get(a:000,0,{})

  let s:obj = {}
  " {
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
      call base#rdw(printf('SUCCESS: URL FETCH'))
    else
      call base#rdwe(printf('FAIL: URL FETCH'))
    endif
  endfunction
  " }
  
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
