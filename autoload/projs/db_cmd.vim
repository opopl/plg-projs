

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
  call projs#db#drop_tables ()
endf

function! projs#db_cmd#buf_data (...)
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
  let data = projs#db#data_get(r)
  let dump = base#dump(data)
  call base#buf#open_split({ 'text' : dump })
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

function! projs#db_cmd#search (...)
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
    \ "    Size: " . data.size(),  
    \ "    Tables: ",  
    \ "       " . data.tables_str(),
    \ "  BACKUP location: ",  
    \ "    " . dbfile_b,  
    \ "    Size: " . data_b.size(),  
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
