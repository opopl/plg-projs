
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

      let type = ''
      let field = ''

      let field_values = {}

      for line in out
        if !len(type)
          let list = matchlist(line, '^print_field\s\+\(\w\+\)\s\(\w\+\)\s*$' )

          if len(list)
            let field = get(list,1,'')
            let type  = get(list,2,'')

            if type == 'list'
              call extend(field_values,{ field : [] })
            endif
          endif

          continue
        endif

        if type == 'list'
          if len(field)
            if !has_key(field_values,field)
              echo line
              break
              "call add(field_values[field],'2')
            endif
          endif
        endif

      endfor

      call add(field_values[field],'2')
      echo field_values
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
