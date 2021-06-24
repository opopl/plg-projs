
function! projs#data#dict#ids ()
	let dict_dir = projs#data#dict#dir()
	let ids = base#find({ 
		\	"dirs"    : [dict_dir],
		\	"exts"    : base#qw('i.dat'),
		\	"cwd"     : 1,
		\	"relpath" : 1,
		\	"subdirs" : 1,
		\	"rmext"   : 1,
		\	"fnamemodify" : '',
		\	})
	let ids = sort(ids)
	let ids = base#uniq(ids)
	return ids
endfunction

function! projs#data#dict#choose ()
	let dict_dir = projs#data#dict#dir()
	let ids = base#find({ 
		\	"dirs"    : [dict_dir],
		\	"exts"    : base#qw('i.dat'),
		\	"cwd"     : 1,
		\	"relpath" : 1,
		\	"subdirs" : 1,
		\	"rmext"   : 1,
		\	"fnamemodify" : '',
		\	})
	call base#varset('this',ids)
	let id = input('dict id: ','','custom,base#complete#this')
	return id

endfunction

function! projs#data#dict#dir (...)
  let ref = get(a:000,0,{})

  let proj = get(ref,'proj','')

  let a = [ projs#root(), 'data', 'dict' ]
  if len(proj)
    call extend(a,[ proj ])
  endif

  let dir = join(a, '/')
	return dir

endfunction

function! projs#data#dict#file (...)
  let ref = get(a:000,0,{})

  let id   = get(ref,'id','')
  let proj = get(ref,'proj','')

	let dict_dir = projs#data#dict#dir({ 'proj' : proj })

	let a = []
  call extend(a,[ dict_dir, printf('%s.i.dat',id) ])

  let file = join(a, '/')
  return file

endfunction
