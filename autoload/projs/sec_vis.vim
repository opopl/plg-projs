
function! projs#sec_vis#open ()
	let lines = base#vim#visual_selection()

	for line in lines
		let sec = matchstr(line,'^\s*\zs\(\w\+\)\ze')
		q
		call projs#sec#open(sec)
	endfor
	
endfunction
