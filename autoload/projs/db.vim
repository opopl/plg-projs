
"
"""prjdb_create_tables

if 0
  Usage
    projs#db#create_tables()
  Call tree
    Calls
        projs#db#file
          projs#root
          db.create_tables from plg.projs.db
        projs#pylib
        pymy#py#add_lib
endif

function! projs#db#alter_tables ()
  let db_file = projs#db#file()

  let pylib   = projs#pylib()
  call pymy#py3#add_lib( pylib . '/plg/projs' )

  let tables   = base#qw('projs tags authors')

  for table in tables
    let sql_file = base#qw#catpath('plg projs data sql alter_table_' . table . '.sql')

    if !filereadable(sql_file)
      continue
    endif

    let msg = [ 'altering table: ', table ]
    let prf = { 'plugin' : 'projs', 'func' : 'projs#db#alter_tables' }
    call base#log(msg, prf)
python3 << eof

import vim
import sqlite3,sqlparse
import db

db_file  = vim.eval('db_file')
sql_file = vim.eval('sql_file')

db.sql_file_exec( db_file, sql_file )

eof
  endfor

endfunction

function! projs#db#author_ids (...)
   let dbfile = projs#db#file()
   
   let q = 'SELECT author_id FROM authors'
   let p = []
   
   let author_ids = pymy#sqlite#query_as_list({
     \  'dbfile' : dbfile,
     \  'p'      : p,
     \  'q'      : q,
     \  })
   return author_ids

endfunction

if 0
  call tree
    called by
      projs#db_cmd#author_add
endif

function! projs#db#author_add (...)
  let ref = get(a:000,0,{})

  let author    = get(ref,'author','')
  let author_id = get(ref,'author_id','')

  let root_id   = get(ref,'root_id','')

  let db_file   = projs#db#file()

python3 << eof

import vim, db

db_file    = vim.eval('db_file')

author     = vim.eval('author')
author_id  = vim.eval('author_id')
root_id    = vim.eval('root_id')

r = {
  'db_file'   : db_file,
  'author'    : author,
  'author_id' : author_id,
  'root_id'   : root_id
}

db.author_add(r)

eof
endfunction

function! projs#db#create_tables ()
  let db_file = projs#db#file()

  let pylib   = projs#pylib()
  call pymy#py3#add_lib( pylib . '/plg/projs' )

  let tables   = base#qw('projs tags authors')

  for table in tables
    let sql_file = base#qw#catpath('plg projs data sql create_table_' . table . '.sql')

    if !filereadable(sql_file)
      continue
    endif

    let msg = [ 'creating table: ', table ]
    let prf = { 'plugin' : 'projs', 'func' : 'projs#db#create_tables' }
    call base#log(msg, prf)
python3 << eof

import vim
import sqlite3,sqlparse
import db

db_file  = vim.eval('db_file')
sql_file = vim.eval('sql_file')

db.sql_file_exec( db_file, sql_file )

eof
  endfor

endfunction

if 0
  Usage:
    projs#db#fill_tags()
endif

function! projs#db#fill_tags (...)
  let dbfile = projs#db#file()

  let script = base#qw#catpath('plg projs scripts db_fill_tags.py3')
  let py3 = 'C:\Python_372_64bit\python.EXE'
  let py3 = base#envvar('PY3_EXE',py3)

  let dbfile_e = shellescape(dbfile)
  let args     = [ shellescape(py3), shellescape(script) ]

  call extend(args,[ '--dbfile' , dbfile_e ])
  let cmd = join(args, ' ')
  
  let env = {}
  function env.get(temp_file) dict
    let code = self.return_code
  
    let ok  = 1
    let out = []
    if filereadable(a:temp_file)
      let out = readfile(a:temp_file)
      for line in out
        if line !~ '^ok'
          let ok = 0
        endif
      endfor
    endif

    if ok
      call base#rdw('ok: fill_tags')
    else
      call base#rdwe('fail: fill_tags')
    endif
  endfunction
  
  call asc#run({ 
    \ 'cmd' : cmd, 
    \ 'Fn'  : asc#tab_restore(env) 
    \ })
  return 1


endfunction

if 0
  Options
    prompt 1 or 0  default 1
"   'all'  1 or 0  default 0
    proj_select 
  Usage
   call projs#db#fill_from_files({
      \ 'prompt'      : prompt,
      \ 'all'         : 1,
      \ })

   call projs#db#fill_from_files({
      \ 'prompt'      : prompt,
      \ 'proj_select' : proj,
      \ })

endif

function! projs#db#fill_from_files (...)
  let ref    = get(a:000,0,{})
  let prompt = get(ref,'prompt',1)

  let proj = projs#varget('db_proj_select',projs#proj#name())
  let proj = get(ref,'proj_select',proj)

  let all = get(ref, 'all' , 0)

  if prompt
    let all = input('all? (1/0):', 1)
    if !all
      let proj = input('selected proj:', proj, 'custom,projs#complete' )
    endif
  endif

  let projs = []
  if all
    let projs = projs#list()
  endif

  call projs#varset('db_proj_select', proj)

  let db_fill_py = base#qw#catpath('plg','projs scripts db_fill.py')
  let py3_exe    = base#envvar('PY3_EXE','python3')

  let cmd_a = [ 
      \ shellescape(py3_exe), 
      \ shellescape(db_fill_py),
      \ "--root"   , projs#root(),
      \ "--dbfile" , projs#db#file(),
    \ ]

  if all
    call extend(cmd_a,[ '-a' ])
  else
    call extend(cmd_a,[ '--proj', proj ])
  endif

  let cmd = join(cmd_a, ' ')
  
  let env = {}
  function env.get(temp_file) dict
    let temp_file = a:temp_file
    let code      = self.return_code
  
    if filereadable(a:temp_file)
      let out = readfile(a:temp_file)
      let tail = remove(out,-1)
      if tail =~ 'OK'
        call base#rdw_printf([ 'OK: fill_from_files; rootid: %s', projs#rootid() ],'MoreMsg')
      else
        call base#rdwe(printf('FAIL: fill_from_files; rootid: %s',projs#rootid()) )
      endif
    endif
  endfunction
  
  call asc#run({ 
    \  'path' : projs#root(), 
    \  'cmd'  : cmd, 
    \  'Fn'   : asc#tab_restore(env) 
    \  })

endfunction

"Usage
" call projs#db#query ({ 
"   \ 'query'  : q,
"   \ 'params' : params,
"   \ })

function! projs#db#query (...)
  let ref   = get(a:000,0,{})

  let query  = get(ref,'query','')
  let params = get(ref,'params',[])

  let rows = []

"""prjdb_query
python3 << eof

import sqlite3
import vim

db_file = vim.eval('projs#db#file()')
query   = vim.eval('query')
params  = vim.eval('params')

conn = sqlite3.connect(db_file)
c = conn.cursor()

rows = []

lines = []
for line in lines:
  vim.command("let row='" + line + "'")
  vim.command("call add(rows,row)")

for row in c.execute(query,params):
  vim.command("let row='" + ' '.join(row) + "'")
  vim.command("call add(rows,row)")
  rows.append(row)

eof
  return rows

endfunction

function! projs#db#query_split (...)
  let ref = get(a:000,0,{})

  let proj = projs#proj#name()

  let table = input('table:','projs')
  let fields = input('SELECT fields:','proj,sec,tags')
  let query = 'SELECT '. fields .' FROM ' . table

  let proj = input('proj:',proj,'custom,projs#complete')
  if len(proj)
    let query = query . ' WHERE proj = "'.proj .'"'
  endif

  let limit = input('limit:','')
  if limit
    let query =  query . ' LIMIT ' . limit 
  endif

  let query  = input('query:',query)

  let rows = []
  call extend(rows, [' ',query,' '])

  let rows_q = projs#db#query({ 'query' : query })
  call extend(rows,rows_q)

  call base#buf#open_split({ 'lines' : rows })
endfunction


"""prjdb_drop_tables
function! projs#db#drop_tables ()
  let db_file = projs#db#file()

  call projs#db#init_py ()

python3 << eof

import vim,sys
import sqlite3

db_file = vim.eval('projs#db#file()')
db.drop_tables(db_file)

eof

endfunction

function! projs#db#init_py ()
python3 << eof

import vim, sys, sqlite3

pylib = vim.eval('projs#pylib()')
pylib += '/plg/projs'

if not pylib in sys.path:
  sys.path.append( pylib )

import db

eof
endfunction

function! projs#db#url_set (...)
  let ref  = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let url = get(ref,'url','')

  let file = exists('b:basename') ? b:basename : ''
  let file = get(ref,'file',file)

  let dbfile  = projs#db#file()
  let dbfile  = get(ref,'dbfile',dbfile)
  
  let t = "projs"
  let h = {
    \ "url" : url,
    \ }
  
  let w = {
    \ "proj" : proj,
    \ "file" : file,
    \ }
  
  let ref = {
    \ "dbfile" : dbfile,
    \ "u"      : "UPDATE",
    \ "t"      : t,
    \ "h"      : h,
    \ "w"      : w,
    \ }
    
  call pymy#sqlite#update_hash(ref)

endfunction

function! projs#db#url (...)
  let ref  = get(a:000,0,{})

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let file = exists('b:basename') ? b:basename : ''
  let file = get(ref,'file',file)

  let q = 'SELECT url FROM projs ' 
    \ . ' WHERE proj = ? AND file = ?'

  let dbfile = projs#db#file()

  let ref = {
      \ 'dbfile' : dbfile,
      \ 'q'      : q,
      \ 'p'      : [ proj, file ],
      \ }

  let url = pymy#sqlite#query_fetchone(ref)
  return url

endfunction

if 0
  Usage
    let secs = projs#db#secnames ()
    call base#buf#open_split({ 'lines' : secs })

    let secs = projs#db#secnames ({ 'ext' : 'pl' })
    call base#buf#open_split({ 'lines' : secs })

    let secs = projs#db#secnames ({ 'pat' : '^aa' })

    let secs = projs#db#secnames ()
    call base#buf#open_split({ 'lines' : secs })

  Return
    LIST - array of secnames
    
  Call tree
    called by
      projs#proj#secnames
endif

function! projs#db#secnames (...)
  let ref  = get(a:000,0,{})

  call projs#db#init_py ()

  let proj = projs#proj#name()

  if base#type(ref) == 'String'
    let proj = ref
  elseif base#type(ref) == 'Dictionary'
    let proj = get(ref,'proj',proj)
  endif

  let ext = get(ref,'ext','')
  let pat = get(ref,'pat','')

  let cond_a = []
  if len(ext)
    call add(cond_a,printf('file LIKE "%%.%s"',ext))
  endif

  let cond = join(cond_a, ' AND ')
  if len(cond)
    let cond = printf(' AND %s',cond)
  endif
  let q = printf('SELECT sec FROM projs WHERE proj = ? %s',cond)
  let ref = {
      \ 'query'  : q,
      \ 'params' : [proj],
      \ 'proj'   : proj,
      \ }
  let secs = projs#db#query(ref)

  if len(pat)
    if pat =~ '\w\+'
      let pat = '.*' . pat . '.*'
    endif
python3 << eof
import vim,re
nsecs = []

secs = vim.eval('secs')
pat  = vim.eval('pat')

pt   = re.compile(pat)

for sec in secs:
  m = pt.match(sec)
  if m:
    nsecs.append(sec)
eof

    let secs = py3eval('nsecs')
  endif

  let fsecs = []
  for sec in secs
    if !projs#sec#exists(sec) | continue | endif

    call add(fsecs,sec)
  endfor

  let fsecs = sort(fsecs)

  return fsecs
endfunction

if 0
  call tree
    called by
      projs#db_cmd#search
endif

function! projs#db#search (...)
  let ref  = get(a:000,0,{})

  let tags = get(ref,'tags',[])

  let dbfile = projs#db#file()

  let cond_a = projs#db#cond_tags({ 'tags' : tags })

  if len(cond_a)
    let cond = ' WHERE ' . join(cond_a, ' AND ')
  endif

  let dbfile = projs#db#file()
  
  let [ rows_h, cols ] = pymy#sqlite#select({
    \  'dbfile' : dbfile,
    \  't'      : 'projs',
    \  'f'      : base#qw('fid'),
    \  'w'      : {},
    \  'cond'   : cond,
    \  })

  let fids = []
  for rh in rows_h
    call add(fids,get(rh,'fid',''))
  endfor

  let data_h = []
  for fid in fids
    let q = 'SELECT * FROM projs WHERE fid = ?'
    let p = [ fid ]
    let [ rwh, cols ] = pymy#sqlite#query_first({
      \ 'dbfile' : dbfile,
      \ 'p'      : p,
      \ 'q'      : q,
      \ })
    call add(data_h,rwh)
  endfor

  return data_h
endfunction

if 0
  -------------------
  projs#db#files
  -------------------

  usage:
    let files = projs#db#files()
    echo files

    let files = projs#db#files({ 'proj' : 'acw' })
    echo files

    let files = projs#db#files({ 
      \ 'tags' : ['doctrine'],
      \ })
    echo files

    let files = projs#db#files({ 
      \ 'tags' : base#qw('doctrine orm'),
      \ })
    echo files

    let files = projs#db#files({ 
      \ 'tags' : 'doctrine,orm',
      \ })
    echo files
  called by:
  -------------------
endif

function! projs#db#cond_tags (...)
  let ref  = get(a:000,0,{})

  let tags = get(ref,'tags',[])

  if type(tags) == type([])
    let tags_a = tags

  elseif type(tags) == type('')
    let tags_a = split(tags,',')

  endif

  let cond_a = []

  if len(tags_a)
    for tg in tags_a
      let c  = ''
      let c .= ' (                    '
      let c .= ' tags LIKE "_tg_"     '
      let c .= ' OR                   '
      let c .= ' tags LIKE "_tg_,%"   '
      let c .= ' OR                   '
      let c .= ' tags LIKE "%,_tg_,%" '
      let c .= ' OR                   '
      let c .= ' tags LIKE "%,_tg_"   '
      let c .= ' )                    '
      let c = substitute(c,'_tg_',tg,'g')
      call add(cond_a,c)
    endfor
  endif

  return cond_a
endf

function! projs#db#files (...)
  let ref  = get(a:000,0,{})

  call projs#db#init_py ()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let w = {}
  if strlen(proj)
   call extend(w,{ 'proj' : proj })
  endif

  let cond = ''

  let tags   = get(ref,'tags',[])
  let tags_a = []

  let cond   = ''
  let cond_a = projs#db#cond_tags({ 'tags' : tags })

  if len(cond_a)
    let cond = ' WHERE ' . join(cond_a, ' AND ')
  endif

  let dbfile = projs#db#file()

  let [ rows_h, cols ] = pymy#sqlite#select({
    \  'dbfile' : dbfile,
    \  't'      : 'projs',
    \  'f'      : base#qw('file'),
    \  'w'      : w,
    \  'cond'   : cond,
    \  })

  let files = [] 
  for rh in rows_h
    call add(files, get(rh,'file','') )
  endfor

  return files
endfunction

function! projs#db#list (...)
  let ref  = get(a:000,0,{})

  let q = 'SELECT DISTINCT proj FROM projs ORDER BY proj'
  let ref = {
      \ 'query'  : q,
      \ 'params' : [],
      \ }
  let rows = projs#db#query(ref)
  return rows
endfunction

if 0
  call tree
    called by
      projs#action#info
endif

function! projs#db#file ()
  let root    = projs#root()
  let db_file = base#file#catfile([ root, 'projs.sqlite' ])

  return db_file
endfunction

"call tree
"  called by
"    projs#db_cmd#_backup 

function! projs#db#file_backup ()
  let db_file_b = base#qw#catpath('db backup projs.sqlite')
  return db_file_b
endfunction

function! projs#db#file_backup_flash ()
  let db_file_b = join([ 'f:', 'db', 'projs.sqlite' ], '/')
  return db_file_b
endfunction

if 0
	usage
		let [ rows_h, cols ] = projs#db#data_get()

		let [ rows_h, cols ] = projs#db#data_get({
			\	'proj' : proj,
			\	})

	call tree
		called by
endif

function! projs#db#buf_data ()
  let proj = exists('b:proj') ? b:proj : projs#proj#name()

  let file = b:file
  let file = fnamemodify(file,':t')

  let r = { 
    \ 'file' : file, 
    \ 'proj' : proj 
    \ }

  let [ rows_h, cols ] = projs#db#data_get(r)
  let row_h            = get(rows_h,0,{})

	return row_h
endif

function! projs#db#data_get (...)
  let ref = get(a:000,0,{})

  let proj = get(ref,'proj','')

  let file = get(ref,'file','')
  let file = fnamemodify(file,':t')

  let sec = get(ref,'sec','')

  let q = 'SELECT * FROM projs'
  let p = []

  if strlen(proj) || strlen(file) || strlen(sec)
    let cond = []
    if strlen(proj)
      call add(cond,' proj = ? ')
      call add(p, proj)
    endif

    if strlen(sec)
      call add(cond,' sec = ? ')
      call add(p, sec)
    endif

    if strlen(file)
      call add(cond,' file = ? ')
      call add(p, file)
    endif

    let q .= ' WHERE ' . join(cond,' AND ')
  endif

  let dbfile = projs#db#file()

  let [ rows_h, cols ] = pymy#sqlite#query({
    \ 'dbfile' : dbfile,
    \ 'p'      : p,
    \ 'q'      : q,
    \ })
  return [ rows_h, cols ]
endfunction

function! projs#db#tags_get (...)
  let ref = get(a:000,0,{})

  let proj = get(ref,'proj','')

  let file = get(ref,'file','')
  let sec  = get(ref,'sec','')

  let file = fnamemodify(file,':t')

  let h = { 'file' : file }
  for k in base#qw('proj sec')
    let v = get(ref,k,'')
    if len(v)
      call extend(h,{ k : v })
    endif
  endfor

  let q = 'SELECT DISTINCT tags FROM projs'
  let p = []

  let cond = []
  for k in base#qw('proj file sec')
    let v = get(h,k,'')
    if strlen(v)
      call add(cond,printf(' %s = ? ',k))
      call add(p, v)
    endif
  endfor

  if len(cond)
    let q .= ' WHERE ' . join(cond,' AND ')
  endif

  let dbfile = projs#db#file()
  
  let tlist = pymy#sqlite#query_as_list({
    \ 'dbfile' : dbfile,
    \ 'p'      : p,
    \ 'q'      : q,
    \ })
  let tags_a = [] 
  for t in tlist
    call extend(tags_a,split(t,','))
  endfor
  let tags_a = base#uniq(tags_a)
  let tags_a = sort(tags_a)

  return tags_a
endfunction

if 0
  
  call projs#db#update_col({ 
    \ 'col'    : col,
    \ 'val'    : new_val,
    \ 'proj'   : proj,
    \ 'sec'    : sec,
    \ 'dbfile' : dbfile,
    \ 'prompt' : 1,
    \ })
endif

function! projs#db#update_col(...)
  let ref = get(a:000,0,{})

  let col = get(ref,'col','')
  let val = get(ref,'val','')

  let sec = get(ref,'sec','')
  let proj = get(ref,'proj','')

  let prompt = get(ref,'prompt',0)
  let dbfile = get(ref,'dbfile',projs#db#file())

  let t = "projs"
  let h = {
    \  col : val,
    \  }

  if col == 'url'
    let url = val

    let b:url = url

    let do_insert = 1
    if prompt
      let do_insert = input('Insert url lines? (1/0): ',do_insert)
    endif
    if do_insert
      call projs#sec#insert_url({ 
        \ 'url' : url, 
        \ 'sec' : sec })
    endif
  endif

  let w = {
      \  'sec'  : sec,
      \  'proj' : proj,
      \  }
  
  let ref = {
    \ "dbfile" : dbfile,
    \ "t"      : t,
    \ "h"      : h,
    \ "w"      : w
    \ }
    
  call pymy#sqlite#update_hash(ref)

  if col == 'tags'
    call projs#db_cmd#fill_tags()
  endif
  
endfunction

function! projs#db#fid_last ()
  let dbfile = projs#db#file()

  let r = {
    \ 'q'      : 'SELECT MAX(fid) FROM projs',
    \ 'p'      : [],
    \ 'dbfile' : dbfile,
    \ }
  let fid = pymy#sqlite#query_fetchone(r)
  return str2nr(fid)
endfunction

function! projs#db#pid_max ()
    let dbfile = projs#db#file()
    let r = {
      \ 'q'      : 'SELECT MAX(pid)+1 FROM projs',
      \ 'p'      : [],
      \ 'dbfile' : dbfile,
      \ }
    let pid = pymy#sqlite#query_fetchone(r)
    let pid = str2nr(pid)
    return pid 
endfunction

function! projs#db#pid ()
  let proj = projs#proj#name()

  let r = {
    \ 'q'      : 'SELECT pid FROM projs WHERE proj = ? and pid IS NOT NULL',
    \ 'p'      : [proj],
    \ 'dbfile' : projs#db#file(),
    \ }
  let pid = pymy#sqlite#query_fetchone(r)
  if !len(pid)
    let pid = projs#db#pid_max()
    let pid = pid + 1
  endif
  return pid
endfunction

if 0
  projs#db#action

  Purpose:
   projs (SQLite) database-related actions
    
  Usage:
    call projs#db#action (act)
  Returns:

  Call tree:
    calls:
      pymy#data#tabulate
      base#buf#open_split
      projs#db_cmd#*
    called by:
      PrjDB
endif

function! projs#db#action (...)
  let act = get(a:000,0,'')

  let acts = base#varget('projs_opts_PrjDB',[])
  let acts = sort(acts)
  if ! strlen(act)
    let desc = base#varget('projs_desc_PrjDB',{})
    let info = []
    for act in acts
      call add(info,[ act, get(desc,act,'') ])
    endfor
    let lines = [ 'Possible PrjDB actions: ' ]
    call extend(lines, pymy#data#tabulate({
      \ 'data'    : info,
      \ 'headers' : [ 'act', 'description' ],
      \ }))

    call base#buf#open_split({ 'lines' : lines })
    return
  endif

  let sub = 'projs#db_cmd#'.act

  exe 'call '.sub.'()'

endfunction

