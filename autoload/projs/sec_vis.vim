
function! projs#sec_vis#open ()
	let lines = base#vim#visual_selection()

	for line in lines
		let sec = matchstr(line,'\zs\(\w\+\)\ze\s*$')
		q
		call projs#sec#open(sec,{ 'load_buf' : 1 })
	endfor
	
endfunction
