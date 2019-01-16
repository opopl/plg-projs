

function! projs#db#init ()
	let db_file = projs#db#file()

	let root   = projs#root()
	let rootid = projs#rootid()

python << eof

from vim import *
from os import walk
from pprint import pprint

import sqlite3
import re

db_file = eval('db_file')
root    = eval('root')
rootid  = eval('rootid')

conn = sqlite3.connect(db_file)
c = conn.cursor()

c.execute('''CREATE TABLE IF NOT EXISTS projs (
	proj text, 
	sec text, 
	rootid text, 
	root text )''')

c.execute('''CREATE TABLE IF NOT EXISTS files (
	file text, 
	rootid text, 
	root text )''')

f = []
for (dirpath, dirnames, filenames) in walk(root):
	f.extend(filenames)
	break

p_texfile=re.compile('^(\w+)\.(.*)\.tex')

x = 0
h_projs = []
for file in f:
	x+=1
	m=p_texfile.match(file)
	if m:
		proj = m.group(1)					
		sec = m.group(2)					
		c.execute('''insert into projs (root,rootid,proj,sec) values (?,?,?,?)''',[root,rootid,proj,sec])

conn.commit()
conn.close()

eof


endfunction

function! projs#db#query (...)
	let proj = projs#proj#name()
	let proj = input('proj:',proj)

	let query = 'select sec from projs where proj = "'.proj .'"'

	let limit = input('limit:',10)
	if limit
		let query =  query . ' limit ' . limit 
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
for row in c.execute(query):
	vim.command("let row='" + ''.join(row) + "'")
	vim.command("call add(rows,row)")
	rows.append(row)

eof
	call base#buf#open_split({ 'lines' : rows })

endfunction

function! projs#db#drop_tables ()
	let db_file = projs#db#file()

python << eof

from vim import *
import sqlite3

db_file = vim.eval('db_file')

conn = sqlite3.connect(db_file)
c = conn.cursor()

c.execute('''DROP TABLE IF EXISTS projs''')
c.execute('''DROP TABLE IF EXISTS files''')

eof

endfunction

function! projs#db#file ()
	let root = projs#root()
	let db_file = base#file#catfile([ root, 'projs.sqlite' ])

	return db_file
endfunction

function! projs#db#update_from_files ()
	let db = 'projs_'.projs_rootid

	let meth = 'python'

	if meth == 'python'
python << eof
						
eof
	elseif meth == 'perl'
perl << eof
	use DBI;
	use Vim::Perl qw(:funcs :vars);

	my $db  = VimVar('db');
	my $dsn = "DBI:mysql:database=$db:host=localhost";
	my $attr={
		RaiseError        => 1,
		PrintError        => 1,
		mysql_enable_utf8 => 1,
	};
	my $dbh = DBI->connect($dsn,$user,$pwd,$attr) || $err->($DBI::errstr);
eof

	endif

endfunction

function! projs#db#action (...)
  let act = get(a:000,0,'')

  let sub = 'projs#db#'.act

  exe 'call '.sub.'()'

endfunction
