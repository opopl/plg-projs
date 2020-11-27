
function! projs#zlan#data ()
	let zfile = projs#sec#file('_zlan_')

	let lines = readfile(zfile)
	let zdata = {}

	let flags = {}
	let d     = {}


	for line in lines
		if line =~ '^page'
			let url = get(d,'url','')
			if len(url)
				unlet d.url
				call extend(zdata,{ url : copy(d) })
			endif

		elseif line =~ '^\t'
			let list = matchlist(line, '^\t\zs%s\s\+.*\ze$')
				"Same as |match()|, but return a |List|.  The first item in the
				"list is the matched string, same as what matchstr() would
				"return.  Following items are submatches, like "\1", "\2", etc.
				"in |:substitute|.  When an optional submatch didn't match an
				"empty string is used.  Example: 
				"echo matchlist('acd', '\(a\)\?\(b\)\?\(c\)\?\(.*\)')
				"Results in: ['acd', 'a', '', 'c', 'd', '', '', '', '', '']
				"When there is no match an empty list is returned.
				"
				"Can also be used as a |method|: >
				"GetList()->matchlist('word')
			
		endif
	endfor

	return zdata
	
endfunction
