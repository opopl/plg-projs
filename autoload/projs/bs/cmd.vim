
function! projs#bs#cmd#run ()
  
endfunction

function! projs#bs#cmd#site_view ()
	let bs_dir = base#qw#catpath('p_sr','scrape bs')
	echo bs_dir

	call base#cd(bs_dir)
	let cmd = 'bs.py -p list_sites -y mix.yaml'
	

"python3 << eof
"import vim
"import os
"import Base.Util as util
"from Base.Scraper.Engine import BS

"plg = os.environ.get('PLG')
"libs = []
"lib = os.path.join(plg,'projs web_scraping py3')
"libs.append(lib)
"util.add_libs(libs)

"eof
  
endfunction
