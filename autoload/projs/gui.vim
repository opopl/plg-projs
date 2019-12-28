
function! projs#gui#proj_toolbar ()
	let projs = projs#list()
	let proj  = projs#proj#name()

  let r = {
      \ 'data'   : { 'projs' : projs, 'proj' : proj },
      \ 'dir'    : base#qw#catpath('plg projs scripts gui'),
      \ 'script' : 'proj_toolbar',
      \ 'args'   : [ '' ],
      \ }
  call base#script#run(r) 
	
endfunction

function! projs#gui#select_project ()
	let projs = projs#list()

  let r = {
      \ 'data'   : { 'projs' : projs },
      \ 'dir'    : base#qw#catpath('plg projs scripts gui'),
      \ 'script' : 'select_project',
      \ 'args'   : [ '-r' ],
      \ }
  call base#script#run(r) 
	
endfunction
