
let rootid = 'texdocs'
let rootid = 'p_saintrussia'

call projs#initvars()

let dir = ap#file#catfile( [ expand('<sfile>:p:r'), '..', '..' ])
call projs#var('plgdir',dir)
call projs#var('datadir',ap#file#catfile([ dir, 'data' ]))

call projs#init(rootid)
