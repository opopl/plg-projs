
function! projs#sec#picture#fetch (...)
  let ref = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let sec  = get(ref,'sec','')

  let file = strlen(sec) ? projs#sec#file(sec) : ''

  let pl   = base#qw#catpath('plg projs scripts bufact tex get_img.pl')
  let pl_e = shellescape(pl)

  let env = { 'proj' : proj }
  if sec
    call extend(env,{ 'sec' : sec })
  endif

  let cmd_a = [ 'perl', pl_e, '-p', proj ]
  if len(file)
    if !filereadable(file) | return | endif

    call extend(cmd_a,[ '-f' , file ])
    call extend(env,{ 'file' : file })
  endif

  let cmd  = join(cmd_a, ' ')
  call extend(env,{ 'cmd' : cmd })
  "call base#buf#open_split({ 'lines' : [cmd] })

  function env.get(temp_file) dict
    let temp_file = a:temp_file
    let code      = self.return_code

    let cmd  = get(self,'cmd','')

    if filereadable(temp_file) 
      let out  = readfile(temp_file)
      let last = get(out,-1,'')

      if last =~ 'SUCCESS:\s\+\(\d\+\)\s\+images' 
        call base#rdw(last)

      elseif last =~ 'NO IMAGES'
        call base#rdw(last,'Conditional')

      else
        call base#rdwe(last)
        call insert(out, cmd, 0)
        call base#buf#open_split({ 'lines' : out })
      endif
    else
    endif
  endfunction
  
  call asc#run({ 
    \ 'path' : projs#root(),
    \ 'cmd'  : cmd,
    \ 'Fn'   : asc#tab_restore(env)
    \ })
  
endfunction
