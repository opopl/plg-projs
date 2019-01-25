
"""prjdb_create_tables
function! projs#db#create_tables ()
	let db_file = projs#db#file()
python << eof

from vim import *
import sqlite3

db_file = eval('db_file')

conn = sqlite3.connect(db_file)
c = conn.cursor()

c.execute('''DROP TABLE IF EXISTS projs''')
c.execute('''CREATE TABLE IF NOT EXISTS projs (
	proj text not null, 
	file text not null unique,
	root text not null,
	sec text, 
	tags text, 
	parent text,
	author text,
	pic text,
	rootid text )''')

conn.commit()
conn.close()

eof

endfunction


"""prjdb_fill_from_files
function! projs#db#fill_from_files (...)
	let ref    = get(a:000,0,{})
	let prompt = get(ref,'prompt',1)

	let db_file = projs#db#file()

	let root   = projs#root()
	let rootid = projs#rootid()

	let proj_select = projs#varget('db_proj_select','')
	let proj_select = get(ref,'proj_select',proj_select)

	if prompt
		let proj_select = input('selected proj:',proj_select,'custom,projs#complete')
	endif

	call projs#varset('db_proj_select',proj_select)

python << eof

from vim import *
from os import walk

import sqlite3
import re

db_file = eval('db_file')

root    = eval('root')
rootid  = eval('rootid')
proj_select  = eval('proj_select')

conn = sqlite3.connect(db_file)
c = conn.cursor()

f = []
for (dirpath, dirnames, filenames) in walk(root):
	f.extend(filenames)
	break

p={}

p['texfile'] = re.compile('^(\w+)\.(?:(.*)\.|)tex')

p['tags']   = re.compile('^\s*%%tags (.*)$')
p['author'] = re.compile('^\s*%%author (.*)$')

def get_data(filename):
	data={}
	with open(filename) as lines:
		for line in lines:
			m = p['tags'].match(line)
			if m:
				data['tags']=m.group(1)
			m = p['author'].match(line)
			if m:
				data['author']=m.group(1)
	return data

x = 0
h_projs = []
for file in f:
	fpath = os.path.join(root,file)
	m = p['texfile'].match(file)
	if m:
		x+=1
		proj = m.group(1)					
		if not ((proj_select) and ( proj == proj_select  )):
			continue
		sec = m.group(2)					
		if not sec: 
			sec = '_main_' 
		data   = get_data(fpath)
		tags   = data.get('tags','')
		author = data.get('author','')
		v_projs = [proj,sec,file,root,rootid,tags,author]
		q = '''insert into projs (proj,sec,file,root,rootid,tags,author) values (?,?,?,?,?,?,?)'''
		try:
			c.execute(q,v_projs)
		except sqlite3.IntegrityError, e:
			" "
		
conn.commit()
conn.close()

eof

endfunction

"""prjdb_query
function! projs#db#query (...)
	let ref = get(a:000,0,{})
	let query = get(ref,'query','')

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

	let root   = projs#root()
	let rootid = projs#rootid()

	let query  = input('query:',query)

	let root   = projs#root()
	let rootid = projs#rootid()

	let db_file = projs#db#file()
	let rows=[]

python << eof

from vim import *
import sqlite3

db_file = eval('db_file')
root    = eval('root')
rootid  = eval('rootid')
query   = eval('query')

conn = sqlite3.connect(db_file)
c = conn.cursor()

rows=[]

lines=[]
lines.extend([' ',query,' '])
for line in lines:
	command("let row='" + line + "'")
	command("call add(rows,row)")

for row in c.execute(query):
	command("let row='" + ' '.join(row) + "'")
	command("call add(rows,row)")
	rows.append(row)

eof
	call base#buf#open_split({ 'lines' : rows })

endfunction



"""prjdb_drop_tables
function! projs#db#drop_tables ()
	let db_file = projs#db#file()

python << eof

from vim import *
import sqlite3

db_file = eval('db_file')

conn = sqlite3.connect(db_file)
c = conn.cursor()

c.execute('''DROP TABLE IF EXISTS projs''')

conn.commit()
conn.close()

eof

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
