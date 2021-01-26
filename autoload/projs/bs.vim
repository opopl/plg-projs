
function! projs#bs#cmd (...)
  let act  = get(a:000,0,'')

  let acts = base#varget('projs_opts_BS',[])

  let proj = projs#proj#name()

  call projs#bld#make_secs()

  let fmt_sub = 'projs#bs#cmd#%s'
  let front = [
      \ 'Current project:' , "\t" . proj,
      \ 'Possible BLD actions: ' 
      \ ]
  let desc = base#varget('projs_desc_BLD',{})

  let Fc = projs#fc#match_proj({ 'proj' : proj })
  
  call base#util#split_acts({
    \ 'act'     : act,
    \ 'acts'    : acts,
    \ 'desc'    : desc,
    \ 'front'   : front,
    \ 'fmt_sub' : fmt_sub,
    \ 'Fc'      : Fc,
    \ })
	
endfunction
