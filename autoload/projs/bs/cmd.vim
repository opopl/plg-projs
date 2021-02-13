
function! projs#bs#cmd#run ()
  
endfunction

function! projs#bs#cmd#site_view ()
  let bs_dir = base#qw#catpath('p_sr','scrape bs')

  call chdir(bs_dir)
  let cmd = 'bs.py -p list_sites -y mix.yaml'
  
  let env = {
    \ 'cmd' : cmd,
    \ }
  function env.get(temp_file) dict
    let temp_file = a:temp_file
    let code      = self.return_code
  
    if filereadable(a:temp_file)
      let out = readfile(a:temp_file)

      let is_list = 0
      for line in out
        let list = matchlist(line, '^print_field\s\+\(\w\+\)\s\(\w\+\)\s*$' )
        if len(list) != 3
          
          echo list
        endif
      endfor
      "call base#buf#open_split({ 'lines' : out })
    endif
  endfunction
  
  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })

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
