

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

function! projs#db_cmd#buf_url_fetch (...)
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
  let q = 'SELECT file FROM projs'

  let dbfile = projs#db#file()
python3 << eof
import vim
import sqlite3
import numpy as np

def f_nz(x): return len(x) > 0
def f_str(x): return str(x)

dbfile = vim.eval('dbfile')
conn   = sqlite3.connect(dbfile)
conn.row_factory = sqlite3.Row
c      = conn.cursor()

# index files
print('indexing files...')
q = 'SELECT file,tags FROM projs'
c.execute(q)
rows = c.fetchall()
fid  = 1
i = 0
for row in rows:
  file = row['file']
  tags = row['tags'].split(',') 
  tags = list(filter(f_nz,tags))
  for tag in tags:
    fids_str = ''
    c.execute('''
      SELECT 
        fid 
      FROM 
        projs 
      WHERE 
        tags LIKE "_tg_,%" 
          OR
        tags LIKE "%,_tg_" 
          OR
        tags LIKE "%,_tg_,%" 
          OR
        tags = "_tg_"
      '''.replace('_tg_',tag))
    c.row_factory = lambda cursor, row: row[0]
    fids = c.fetchall()
    fids = list(set(fids))
    fids.sort()
    fids = map(f_str,fids)
    fids_str = ",".join(fids)
    q = '''INSERT OR REPLACE INTO tags (tag,fids) VALUES (?,?)'''
    c.execute(q,(tag,fids_str))
  q = '''UPDATE projs SET fid = ? WHERE file = ?'''
  c.execute(q,(fid, file))
  fid+=1
  i+=1

# index projects
#print('indexing projects...')
#q = 'SELECT DISTINCT proj FROM projs'
#c.execute(q)
#rows = c.fetchall()
#pid  = 1
#i = 0
#for row in rows:
#  proj = row[0]
#  q = '''UPDATE projs SET pid = ? WHERE proj = ?'''
#  c.execute(q,( pid, proj ) )
#  pid+=1

#c.execute('''
#  INSERT INTO tags (tag,) VALUES ()
#''')

conn.commit()
conn.close()
  
eof


endfunction

function! projs#db_cmd#search ()
  let proj = projs#proj#name()

  let tags_a = projs#db#tags_get()

  call base#varset('this',tags_a)
  let tag = input('tags: ','','custom,base#complete#this')

  let q = 'SELECT fid FROM tags WHERE tag = ?'
  let p = [ tag ]
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

function! projs#db_cmd#_backup (...)
  let dbfile = projs#db#file()

  " backup location
  let dbfile_b = projs#db#file_backup()

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
    redraw!
    echohl WarningMsg
    echo 'Projs Backup Aborted.'
    echohl None
    return
  else
    call base#file#copy(dbfile, dbfile_b)
    redraw!
    echohl MoreMsg
    echo 'Projs Backup OK'
    echohl None
    return
  endif
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
