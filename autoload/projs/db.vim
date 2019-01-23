

"""prjdb_init
function! projs#db#init ()
	let db_file = projs#db#file()

	let root   = projs#root()
	let rootid = projs#rootid()

	let proj_select = projs#varget('db_proj_select','')
	let proj_select = input('selected proj:',proj_select,'custom,projs#complete')

	call projs#varset('db_proj_select',proj_select)

python << eof

from vim import *
from os import walk
from pprint import pprint

import sqlite3
import re

db_file = eval('db_file')
root    = eval('root')
rootid  = eval('rootid')
proj_select  = eval('proj_select')

conn = sqlite3.connect(db_file)
c = conn.cursor()

c.execute('''CREATE TABLE IF NOT EXISTS projs (
	proj text, 
	sec text, 
	tags text, 
	parent text,
	author text,
	fileid integer, 
	rootid text, 
	root text )''')

c.execute('''CREATE TABLE IF NOT EXISTS files (
	file text, 
	fileid integer, 
	rootid text, 
	tags text, 
	proj text, 
	sec text, 
	root text )''')

f = []
for (dirpath, dirnames, filenames) in walk(root):
	f.extend(filenames)
	break

p_texfile = re.compile('^(\w+)\.(?:(.*)\.|)tex')

p_tags   = re.compile('^\s*%%tags (.*)$')
p_author = re.compile('^\s*%%author (.*)$')

def get_data(filename):
	data={}
	with open(filename) as lines:
		for line in lines:
			m = p_tags.match(line)
			if m:
				data['tags']=m.group(1)
			m = p_author.match(line)
			if m:
				data['author']=m.group(1)
	return data

x = 0
h_projs = []
for file in f:
	m = p_texfile.match(file)
	if m:
		x+=1
		proj = m.group(1)					
		if not ((proj_select) and ( proj == proj_select  )):
			continue
		sec = m.group(2)					
		if not sec: 
			sec = '_main_' 
		data   = get_data(file)
		tags   = data.get('tags','')
		author = data.get('author','')
		v_projs = [proj,sec,root,rootid,tags,author]
		v_files = [file,root,rootid,proj,sec,tags]
		c.execute('''insert into projs (proj,sec,root,rootid,tags,author) values (?,?,?,?,?,?)''',v_projs)
		c.execute('''insert into files (file,root,rootid,proj,sec,tags) values (?,?,?,?,?,?)''',v_files)

conn.commit()
conn.close()

eof

endfunction

"""prjdb_query
function! projs#db#query (...)
	let proj = projs#proj#name()
	let proj = input('proj:',proj,'custom,projs#complete')

	let fields = input('SELECT fields:','proj,sec,tags')

	let query = 'SELECT '.fields.' FROM projs WHERE proj = "'.proj .'"'

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
