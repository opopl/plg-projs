

if 0
  called by
    projs#pdf#invoke
endif

function! projs#pdf#invoke#bld_view (...)
  call projs#pdf#view({ 'type' : 'bld'})

endf

function! projs#pdf#invoke#bare_view (...)
  call projs#pdf#view({ 'type' : 'bare'})

endf
