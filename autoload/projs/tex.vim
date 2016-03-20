
function! projs#tex#kpsewhich (cmd)

  let cmd='kpsewhich ' . a:cmd
  let lines=base#splitsystem(cmd)

  return join(lines,',')

endfunction
