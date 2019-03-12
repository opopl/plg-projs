
"""prjdb_create_tables
function! projs#db#create_tables ()
	let db_file = projs#db#file()
	let pylib   = projs#pylib()

	call pymy#py#add_lib(pylib)

python << eof

import vim
import sqlite3
import plg.projs.db as db

db_file = vim.eval('db_file')
db.create_tables(db_file)

eof

endfunction


"""prjdb_fill_from_files
function! projs#db#fill_from_files (...)
	let ref    = get(a:000,0,{})
	let prompt = get(ref,'prompt',1)

	let proj_select = projs#varget('db_proj_select','')
	let proj_select = get(ref,'proj_select',proj_select)

	if prompt
		let proj_select = input('selected proj:',proj_select,'custom,projs#complete')
	endif

	call projs#varset('db_proj_select',proj_select)

python << eof

import vim,sys,sqlite3,re,os,pprint

pylib = vim.eval('projs#pylib()')
sys.path.append(pylib)
import plg.projs.db as db

db_file = vim.eval('projs#db#file()')
root    = vim.eval('projs#root()')
rootid  = vim.eval('projs#rootid()')
proj_select  = vim.eval('proj_select')

def logfun(e):
	vim.command('let e="' + e +'"')
	vim.command('call base#log(e)')

db.fill_from_files(db_file,root,rootid,proj_select,logfun)

eof

endfunction

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

rows=[]

lines=[]
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

python << eof

import vim,sys
import sqlite3

pylib = vim.eval('projs#pylib()')
sys.path.append(pylib)
import plg.projs.db as db

db_file = vim.eval('projs#db#file()')
db.drop_tables(db_file)

eof

endfunction

function! projs#db#init_py ()
python << eof

import vim,sys
import sqlite3

pylib = vim.eval('projs#pylib()')
sys.path.append(pylib)
import plg.projs.db as db
	
eof
endfunction


function! projs#db#secnames (...)
	call projs#db#init_py ()

	let ref = get(a:000,0,{})
	let proj = projs#proj#name()

	if base#type(ref) == 'String'
		let proj = ref
	elseif base#type(ref) == 'Dictionary'
		let proj = get(ref,'proj',proj)
	endif

	let q = 'SELECT sec FROM projs WHERE proj = ?'
	let ref = {
			\	'query'  : q,
			\	'params' : [proj],
			\	'proj'   : proj,
			\	}
	let rows = projs#db#query(ref)
	return rows
endfunction

function! projs#db#file ()
	let root = projs#root()
	let db_file = base#file#catfile([ root, 'projs.sqlite' ])

	return db_file
endfunction

function! projs#db#action (...)
  let act = get(a:000,0,'')

  let sub = 'projs#db#'.act

  exe 'call '.sub.'()'

endfunction
