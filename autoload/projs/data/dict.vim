
function! projs#data#dict#ids ()
	let dict_dir = projs#data#dict#dir()
	let ids = base#find({ 
		\	"dirs"    : [dict_dir],
		\	"exts"    : base#qw('i.dat'),
		\	"relpath" : 1,
		\	"subdirs" : 1,
		\	"rmext"   : 1,
		\	"fnamemodify" : '',
		\	})
	let ids = sort(ids)
	let ids = base#uniq(ids)
	return ids
endfunction

function! projs#data#dict#get (...)
	let ref = get(a:000,0,{})

  let id   = get(ref,'id','')
  let proj = get(ref,'proj','')
	let key  = get(ref,'key','')

	let dict = projs#data#dict({
			\	'id'   : id,
			\	'proj' : proj,
			\	})
	let val = get(dict,val,'')
	return val

endfunction

function! projs#data#dict#choose ()
	let dict_dir = projs#data#dict#dir()
	let ids = base#find({ 
		\	"dirs"    : [dict_dir],
		\	"exts"    : base#qw('i.dat'),
		\	"cwd"     : 0,
		\	"relpath" : 1,
		\	"subdirs" : 1,
		\	"rmext"   : 1,
		\	"fnamemodify" : '',
		\	})
	call base#varset('this',ids)
	let id = input('dict id: ','','custom,base#complete#this')
	return id

endfunction

if 0
	let upd = { 1 : 1 } | call projs#data#dict#update({ 'id' : 'authors', 'upd' : upd })
endif

function! projs#data#dict#update (...)
  let ref = get(a:000,0,{})

  let id   = get(ref,'id','')
  let proj = get(ref,'proj','')
	let upd  = get(ref,'upd',{})

	let file = projs#data#dict#file({ 
			\	'id'   : id,
			\	'proj' : proj,
			\	})

  if !filereadable(file) | return | endif
    
  let dict = base#readdict({ 'file' : file })
	call extend(dict,upd)

  let kk = sort(keys(dict))
  let kk = base#uniq(kk)

	let lines = [] 
	for k in kk 
		let v = get(dict,k,'')
    call add(lines, printf('%s %s', k, v ))
	endfor

  call writefile(lines,file)

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
