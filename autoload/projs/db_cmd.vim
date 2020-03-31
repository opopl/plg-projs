

function! projs#db_cmd#create_tables ()
  call projs#db#create_tables ()
endf

function! projs#db_cmd#fill_from_files (...)
  call projs#db#fill_from_files ()
endf

function! projs#db_cmd#query_split (...)
  call projs#db#query_split ()
endf

function! projs#db_cmd#drop_tables ()
  let do_drop = input('This will drop projs plugin SQLITE tables; are you sure? (1/0): ',0)
  if !do_drop
    redraw!
    echohl WarningMsg
    echo 'Dropping aborted'
    echohl None
    return
  endif

  call projs#db#drop_tables ()
endf

function! projs#db_cmd#buf_data (...)
  let ref = get(a:000,0,{})

  let proj = exists('b:proj') ? b:proj : projs#proj#name()
  let proj = get(ref,'proj',proj)

  let file = b:file
  let file = get(ref,'file',file)
  let file = fnamemodify(file,':t')

  let r = { 
    \ 'file' : file, 
    \ 'proj' : proj 
    \ }

  let [ rows_h, cols ] = projs#db#data_get(r)
  let row_h            = get(rows_h,0,{})

  let data_kv = []
  for col in cols
    call add(data_kv,{ 
      \ 'key'   : col,
      \ 'value' : get(row_h,col,'') })
  endfor

  let lines = pymy#data#tabulate({
    \ 'data_h'  : data_kv,
    \ 'headers' : [ 'key', 'value' ],
    \ })

  let cmds = [
    \ 'resize 99',
    \ "vnoremap <silent><buffer> u :'<,'>call projs#db_vis#update()<CR>",
    \ ]

  call base#buf#open_split({ 
    \ 'lines'    : lines ,
    \ 'cmds_pre' : cmds ,
    \ 'stl_add'  : [ 
        \ '%4* V[ u - update ]' , 
        \ '%2* %{projs#proj#name()} %0*' ,
        \ '%1* %{projs#proj#secname()} %0*', 
        \ ],
    \ })
  return
endf

function! projs#db_cmd#buf_url_view_in_browser()
  let url = ''
  let url_db =  projs#db#url({ 
      \ 'file' : b:basename })

  call base#html#view_in_browser({ 'url' : url_db })
 
endf

function! projs#db_cmd#buf_url_fetch (...)  

  let url = ''

  let url_db =  projs#db#url({ 
    \ 'file' : b:basename })
  let url = url_db

  if !strlen('url_db')
    if exists("b:url")
      let url = b:url
    endif
  endif

  if !strlen(url)
    call base#rdwe('url not defined!')
    return 
  endif

  let cmd = printf('links -dump %s', shellescape(url) )

  let env = { 'file' : b:basename }
  function env.get(temp_file) dict
    let code = self.return_code
  
    if filereadable(a:temp_file)
      let out = readfile(a:temp_file)
      call base#append#arr(out)
      "call base#buf#open_split({ 'lines' : out })
    endif
  endfunction
  
  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })
endf

function! projs#db_cmd#buf_url_insert (...)
  let ref = get(a:000,0,{})

  let msg_a = [
    \ "(PrjDB) This buffer URL: ",  
    \ ]
  let msg = join(msg_a,"\n")
  let url = base#input_we(msg,'',{ })

  let proj = b:proj
  let proj = get(ref,'proj',proj)

  let file     = b:file
  let file     = get(ref,'file',file)
  let file_rel = fnamemodify(file,':t')

python3 << eof
import vim
import in_place

file_rel = vim.eval('file_rel')
  
eof

  call pymy#sqlite#update_hash({
    \ 'dbfile' : projs#db#file(),
    \ 'h' : { 'url' : url },
    \ 't' : 'projs',
    \ 'u' : 'UPDATE',
    \ 'w' : { 
      \ 'proj' : proj, 
      \ 'file' : file_rel 
      \ },
    \ })
endf

function! projs#db_cmd#buf_tags_append (...)
  let ref = get(a:000,0,{})

  let proj = b:proj
  let proj = get(ref,'proj',proj)

  let file = b:file
  let file = get(ref,'file',file)
  let file = fnamemodify(file,':t')

  let r = { 
    \ 'file' : file, 
    \ 'proj' : proj 
    \ }
  let tags_a = projs#db#tags_get(r)

  call base#varset('this',tags_a)

  let tags_i = input('tags: ','','custom,base#complete#this')
  call extend(tags_a,split(tags_i,','))
  
  let tags_a = base#uniq(tags_a)
  let tags = join(tags_a, ',')

  call pymy#sqlite#update_hash({
    \ 'dbfile' : projs#db#file(),
    \ 'h' : { 'tags' : tags },
    \ 't' : 'projs',
    \ 'u' : 'UPDATE',
    \ 'w' : { 'proj' : proj, 'file' : file },
    \ })

endfunction

""" fill the 'tags' table
function! projs#db_cmd#fill_tags ()
  call projs#db#fill_tags()
endfunction

function! projs#db_cmd#search ()
  let proj = projs#proj#name()

  "let tags_a = projs#db#tags_get()
  "call base#varset('this',tags_a)

  let dbfile = projs#db#file()

  let msg_a = [
      \  '  ',  
      \  'available modes ',  
      \  '  ',  
      \  '  1 - by tags',  
      \  '  2 - by full url',  
      \  '  3 - by url host',  
      \  '  ',  
      \  'select mode: ',  
      \  ]
  let mode = input( join(msg_a, "\n"), 1)

  let tags     = ''
  let url      = ''
  let url_host = ''

  """ select by tags
  if mode == 1
    let tags = input('tags: ', '', 'custom,projs#complete#db_tags')

  " full_url
  elseif mode == 2
    let url = input('url: ', '')

  " url_host
  elseif mode == 3
    let url_host = input('url host: ', '')

  endif

  let r = {}
  if len(tags)
    call extend(r,{ 'tags' : tags })
  endif

  if len(url)
    call extend(r,{ 'url' : url })
  endif

  let data_h = projs#db#search(r)

  let head_s  = 'proj,sec,tags'
  let head_s  = input('headers (comma-separated): ',head_s)
  let headers = split(head_s, ',' )

  let lines = pymy#data#tabulate({
    \ 'data_h'  : data_h  ,
    \ 'headers' : headers ,
    \ })

  let stl_add = [
    \ '[ %2* v - view %0* ]'
    \ ]

  let cmds_after = [
    \ 'resize99',
    \ 'vnoremap <silent><buffer> v :call projs#db_cmd#search#visual_open()<CR>',
    \ ]

  call base#buf#open_split({ 
    \ 'lines'      : lines ,
    \ 'cmds_after' : cmds_after,
    \ 'stl_add'    : stl_add,
    \ })

endfunction

function! projs#db_cmd#thisproj_data (...)
  let proj = projs#proj#name()
  
  let q = 'SELECT sec, tags, file FROM projs WHERE proj = ?'
  let p = [ proj ]
  let [ rows_h, cols ] = pymy#sqlite#query({
    \ 'dbfile' : projs#db#file(),
    \ 'p'      : p,
    \ 'q'      : q,
    \ })

  let lines = pymy#data#tabulate({
    \ 'data_h'  : rows_h,
    \ 'headers' : cols,
    \ })

  call base#buf#open_split({ 'lines' : lines })
endfunction

function! projs#db_cmd#load_to_xml (...)

endfunction

function! projs#db_cmd#save_to_xml (...)
  let xmlfile = projs#xmlfile() 
  let dbfile  = projs#db#file()
python3 << eof
import vim
import xml.etree.ElementTree as ET
from xml.etree.ElementTree import Element, SubElement, Comment, tostring
from xml.dom import minidom

import sqlite3

def prettify(elem):
    """Return a pretty-printed XML string for the Element.
    """
    rough_string = ElementTree.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")

xmlfile = vim.eval('xmlfile')
dbfile  = vim.eval('dbfile')

conn = sqlite3.connect(dbfile)
conn.row_factory = sqlite3.Row 

c = conn.cursor()

e_root = Element('projs')

i=0
c.execute('SELECT DISTINCT proj FROM projs ORDER BY proj')
rows_projs = c.fetchall()
for r in rows_projs:
  proj = r['proj']
  e_proj = SubElement(e_root,'proj')
  e_proj.attrib['name'] = proj
  q = 'SELECT sec FROM projs WHERE proj = ?'
  c.execute(q,(proj,))
  rows_secs = c.fetchall()
  for rs in rows_secs:
    sec = rs['sec']
    e_sec = SubElement(e_proj,'sec')
    e_sec.attrib['name'] = sec
    q = 'SELECT * FROM projs WHERE proj = ? and sec = ? '
    c.execute(q,(proj,sec,))
    rows = c.fetchall()
    for rss in rows:
      for k in rss.keys():
        if k not in ['proj','sec']:
	        e_k = SubElement(e_sec,k)
	        val = str(rss[k])
	        e_k.text = val

conn.close()
xml = prettify(e_root)
eof
  let xml = py3eval('xml')
  let xmllines = split(xml,"\n")
  let r = {
        \   'lines'  : xmllines,
        \   'file'   : xmlfile,
        \   'prompt' : 0,
        \   'mode'   : 'rewrite',
        \   }
  call base#file#write_lines(r)  

endfunction

function! projs#db_cmd#pids_update (...)
  let dbfile = projs#db#file()

	let q = 'SELECT DISTINCT proj FROM projs'
	let p = []
	
	let projs = pymy#sqlite#query_as_list({
		\	'dbfile' : dbfile,
		\	'p'      : [],
		\	'q'      : q,
		\	})

	let pid = 1 
	for proj in projs	
			let t = "projs"
			let h = {
				\	"pid" : pid,
				\	}

			let w = {
				\	"proj" : proj,
				\	}
			
			let ref = {
				\ "dbfile" : dbfile,
				\ "u" : "UPDATE",
				\ "t" : t, 
				\ "h" : h, 
				\ "w" : w, 
				\ }
				
			call pymy#sqlite#update_hash(ref)
			let pid += 1
	endfor

endfunction

function! projs#db_cmd#thisproj_pid_to_null (...)
	let files = projs#db#files()

	let proj = projs#proj#name()
	let dbfile = projs#db#file()

	for file in files
		let q = 'UPDATE projs SET pid = NULL WHERE proj = ? AND file = ? '
		let p = [proj , file ]
		let [ rows_h, cols ] = pymy#sqlite#query({
			\	'dbfile' : dbfile,
			\	'p'      : p,
			\	'q'      : q,
			\	})
	endfor

endfunction

function! projs#db_cmd#_backup (...)
  let dbfile = projs#db#file()

  " backup location
  let dbfiles_b = []

  call extend(dbfiles_b,[
      \ projs#db#file_backup(),
      \ projs#db#file_backup_flash(),
      \ ])

  for dbfile_b in dbfiles_b
    let data   = pymy#sqlite#db_data({ 'dbfile' : dbfile })
    let data_b = pymy#sqlite#db_data({ 'dbfile' : dbfile_b })
  
    let msg_a = [
      \ "------------------------", 
      \ "PROJS DATABASE BACKUP",  
      \ "------------------------", 
      \ "  CURRENT database location: ",  
      \ "    " . dbfile,  
      \ "    Size:  " . data.size(),  
      \ "    mtime: " . data.mtime(),  
      \ "    Tables: ",  
      \ "       " . data.tables_str(),
      \ "  BACKUP location: ",  
      \ "    " . dbfile_b,  
      \ "    Size:  " . data_b.size(),  
      \ "    mtime: " . data_b.mtime(),  
      \ "    Tables: ",  
      \ "       " . data_b.tables_str(),
      \ "Are you sure to do backup? (1/0): ", 
      \ ]
    let msg = join(msg_a,"\n")
    let do_backup = base#input_we(msg,0,{ })
  
    if ! do_backup
      call base#rdwe('Projs Backup Aborted.')
    else
      call base#file#copy(dbfile, dbfile_b)
      call base#rdw('Projs Backup OK.')
    endif

  endfor
endfunction

function! projs#db_cmd#_restore (...)
  let dbfile = projs#db#file()

  " backup location
  let dbfile_b = projs#db#file_backup()
  
  let msg_a = [
    \ "------------------------", 
    \ "PROJS DATABASE RESTORE (FROM BACKUP)",  
    \ "------------------------", 
    \ "Current database location: ",  
    \ "  " . dbfile,  
    \ "Backup location (from where to restore): ",  
    \ "  " . dbfile_b,  
    \ "Are you sure to do restore? (1/0): ", 
    \ ]
  let msg = join(msg_a,"\n")
  let do_restore = base#input_we(msg,0,{ })

  if ! do_restore
    redraw!
    echohl WarningMsg
    echo 'Projs Restore Aborted.'
    echohl None
    return
  else
    call base#file#copy(dbfile_b, dbfile)
    redraw!
    echohl MoreMsg
    echo 'Projs Restore OK'
    echohl None
    return
  endif
endfunction

function! projs#db_cmd#sec_add_tags (...)
  let msg_a = [
    \  "Select proj: ",  
    \  ]
  let msg  = join(msg_a,"\n")
  let proj = base#input_we(msg,'',{ 
    \ 'complete' : 'custom,projs#complete' 
    \ })

  call projs#proj#name(proj)
 
  let secs = projs#db#secnames({ 'proj' : proj })

  let data = []
  for sec in sort(secs)
    let tags_a = projs#db#tags_get({ 'sec' : sec, 'proj' : proj })
    let tags = join(tags_a, ',')
    let r = { 
      \ 'sec'  : sec,
      \ 'tags' : tags
      \ }
    call add(data, r)
  endfor

  let lines = pymy#data#tabulate({
    \ 'data_h'    : data,
    \ 'headers'   : [ 'sec','tags' ],
    \ })
  call insert(lines,[ 'List of Sections' ])

  let cmds_after = [ 
    \ 'resize99',
    \ 'vnoremap <silent><buffer> u :call projs#db_cmd#sec_add_tags#update()<CR>',
    \ 'vnoremap <silent><buffer> v :call projs#db_cmd#sec_add_tags#view()<CR>',
    \ ]

  let stl_add = [
      \  '[ %3* u - update %4* v - view %0* ]'  
      \  ]

  call base#buf#open_split({ 
    \ 'lines'        : lines,
    \ 'cmds_after'   : cmds_after,
    \ 'stl_add'      : stl_add,
    \ })
endfunction
