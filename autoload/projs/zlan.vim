
function! projs#zlan#import ()
	let zfile = projs#sec#file('_zlan_')

	let lines = readfile(zfile)
	let zdata = {}

	let flags = {}
	let d = {}

	for line in lines
		if line =~ '^page'
			let url = get(d,'url','')
			if len(url)
				unlet d.url
				call extend(zdata,{ url : copy(d) })
			endif
		endif
	endfor
	
endfunction
