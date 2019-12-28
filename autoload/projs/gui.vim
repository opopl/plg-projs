
function! projs#gui#proj_toolbar ()
	
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
