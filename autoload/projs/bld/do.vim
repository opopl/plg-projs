
function! projs#bld#do#show_trg ()
  let proj = projs#proj#name()
  let root    = projs#root()

  call projs#bld#make_secs()

  let bfile = projs#sec#file('_perl.bld')

  call chdir(root)

  let a = [ 'perl', bfile, 'show_trg' ]

  let cmd = join(a, ' ' )

  let env = {
    \ 'proj'    : proj,
    \ 'root'    : root,
    \ 'cmd'     : cmd,
    \ }
  
  function env.get(temp_file) dict
    let temp_file = a:temp_file
    let code      = self.return_code
  
    if filereadable(a:temp_file)
      let out = readfile(a:temp_file)
      call base#buf#open_split({ 'lines' : out })
    endif
  endfunction
  
  call asc#run({ 
    \  'cmd' : cmd, 
    \  'Fn'  : asc#tab_restore(env) 
    \  })
endfunction
