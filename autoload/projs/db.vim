
"
"""prjdb_create_tables

"Usage
" projs#db#create_tables()
"Call tree
" Calls
"   projs#db#file
"     projs#root
"     db.create_tables from plg.projs.db
"   projs#pylib
"   pymy#py#add_lib

function! projs#db#create_tables ()
  let db_file = projs#db#file()
  let pylib   = projs#pylib()

  let tables   = base#qw('projs tags')

  call pymy#py#add_lib( pylib . '/plg/projs' )
  for table in tables
    let sql_file = base#qw#catpath('plg projs data sql create_table_' . table . '.sql')
python << eof

import vim
import sqlite3
import db

db_file  = vim.eval('db_file')
sql_file = vim.eval('sql_file')

db.create_tables( db_file, sql_file )

eof
  endfor

endfunction

"Call tree
"  Calls:
"    projs#db_cmd#fill_from_files

"""prjdb_fill_from_files
function! projs#db#fill_from_files (...)
  let ref    = get(a:000,0,{})
  let prompt = get(ref,'prompt',1)

  let proj_select = projs#varget('db_proj_select',projs#proj#name())
  let proj_select = get(ref,'proj_select',proj_select)

  if prompt
    let proj_select = input('selected proj:',proj_select,'custom,projs#complete')
  endif

  call projs#varset('db_proj_select',proj_select)

python << eof

import vim,sys,sqlite3,re,os,pprint

pylib = vim.eval('projs#pylib()')
sys.path.append(pylib + '/plg/projs')
import db 

db_file     = vim.eval('projs#db#file()')
root        = vim.eval('projs#root()')
rootid      = vim.eval('projs#rootid()')
proj_select = vim.eval('proj_select')

def logfun(e):
  vim.command('let e="' + e +'"')
  vim.command('call base#log(e)')

db.fill_from_files(db_file,root,rootid,proj_select,logfun)

eof

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

  let rows=[]

"""prjdb_query
python << eof

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

python << eof

import vim,sys
import sqlite3

db_file = vim.eval('projs#db#file()')
db.drop_tables(db_file)

eof

endfunction

function! projs#db#init_py ()
python << eof

import vim, sys, sqlite3

pylib = vim.eval('projs#pylib()')
pylib += '/plg/projs'

if not pylib in sys.path:
  sys.path.append( pylib )

import db

eof
endfunction

function! projs#db#secnames (...)
  call projs#db#init_py ()

  let ref  = get(a:000,0,{})
  let proj = projs#proj#name()

  if base#type(ref) == 'String'
    let proj = ref
  elseif base#type(ref) == 'Dictionary'
    let proj = get(ref,'proj',proj)
  endif

  let q = 'SELECT sec FROM projs WHERE proj = ?'
  let ref = {
      \ 'query'  : q,
      \ 'params' : [proj],
      \ 'proj'   : proj,
      \ }
  let rows = projs#db#query(ref)
  return rows
endfunction

function! projs#db#files (...)
  let ref  = get(a:000,0,{})

  call projs#db#init_py ()

  let proj = projs#proj#name()
  let proj = get(ref,'proj',proj)

  let q = 'SELECT file FROM projs WHERE proj = ?'
  let ref = {
      \ 'query'  : q,
      \ 'params' : [proj],
      \ }
  let rows = projs#db#query(ref)
  return rows
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

function! projs#db#file ()
  let root    = projs#root()
  let db_file = base#file#catfile([ root, 'projs.sqlite' ])

  return db_file
endfunction

function! projs#db#data_get (...)
  let ref = get(a:000,0,{})

  let proj = get(ref,'proj','')

  let file = get(ref,'file','')
  let file = fnamemodify(file,':t')

  let q = 'SELECT * FROM projs'
  let p = []

  if strlen(proj) || strlen(file)
    let cond = []
    if strlen(proj)
      call add(cond,' proj = ? ')
      call add(p, proj)
    endif

    if strlen(file)
      call add(cond,' file = ? ')
      call add(p, file)
    endif

    let q .= ' WHERE ' . join(cond,' AND ')
  endif

  let dbfile = projs#db#file()

  let rows = pymy#sqlite#query({
    \ 'dbfile' : dbfile,
    \ 'p'      : p,
    \ 'q'      : q,
    \ })
	return rows
endfunction

function! projs#db#tags_get (...)
  let ref = get(a:000,0,{})

  let proj = get(ref,'proj','')

  let file = get(ref,'file','')
  let file = fnamemodify(file,':t')

  let q = 'SELECT DISTINCT tags FROM projs'
  let p = []

  if strlen(proj) || strlen(file)
    let cond = []
    if strlen(proj)
      call add(cond,' proj = ? ')
      call add(p, proj)
    endif

    if strlen(file)
      call add(cond,' file = ? ')
      call add(p, file)
    endif

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

  return tags_a
endfunction

"  projs#db#action
"
"  Purpose:
"   projs (SQLite) database-related actions
"    
"  Usage:
"    call projs#db#action (act)
"  Returns:
"
"  Call tree:
"    calls:
"      pymy#data#tabulate
"      base#buf#open_split
"      projs#db_cmd#*
"    called by:
"      PrjDB

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
