
function! projs#sec#url#fetch (sec,...)
	let ref = get(a:000,0,{})

	let sec = a:sec


endfunction

function! projs#sec#url#local (sec,...)
  let sec = a:sec

	let ref = get(a:000,0,{})

	let proj = projs#proj#name()
	let proj = get(ref,'proj',proj)

  let bname = join(filter([ proj, sec, 'html' ],'strlen(v:val) > 0' ), '.')

  let ofile = join([ projs#url_dir(), bname ], '/')
  call base#mkdir(projs#url_dir())

  return ofile

endfunction
