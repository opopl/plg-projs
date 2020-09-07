
if 0
  TgAdd perl_inc_plg_projs
  TgAdd perl_inc_plg_base
  tag Plg::Base::Dialog
  tag Plg::Projs::Dialog::ControlPanel
endif

function! projs#gui#control_panel ()
  let projs = projs#list()
  let proj  = projs#proj#name()
  
  let data = { 
    \ 'projs' : projs, 
    \ 'proj'  : proj ,
    \ 'vim'  : { 
      \ 'servername' : v:servername,
      \ }
    \ }

  let r = {
      \ 'data'   : data,
      \ 'dir'    : base#qw#catpath('plg projs scripts gui'),
      \ 'script' : 'control_panel',
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
